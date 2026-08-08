// lib/presentation/providers/realtime/realtime_bridge.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/websocket/pusher_connection_state.dart';
import '../../../core/network/websocket/pusher_event.dart';
import '../../../core/network/websocket/realtime_channels.dart';
import '../../../core/network/websocket/websocket_config.dart';
import '../../../core/network/websocket/websocket_providers.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/appointment/appointment_model.dart';
import '../../../data/models/notification/notification_model.dart';
import '../../pages/dashboard/dashboard_providers.dart';
import '../appointment/appointment_provider.dart';
import '../auth/auth_provider.dart';
import '../notification/notification_provider.dart';

/// Keeps the socket's lifetime tied to the session, and fans incoming events
/// into the existing state notifiers.
///
/// This is the only place features touch the socket. Feature data deliberately
/// does NOT flow through StreamProviders: the lists and counts already live in
/// StateNotifiers that HTTP writes to, and a parallel stream would be a second
/// source of truth needing reconciliation. Events call the same local mutators
/// a manual refresh would.
///
/// Everything here is additive. Every RefreshIndicator and refresh button keeps
/// working, and with the socket down the app behaves exactly as it did before.
final realtimeBridgeProvider = Provider<RealtimeBridge>((ref) {
  final bridge = RealtimeBridge(ref);
  ref.onDispose(bridge.dispose);
  return bridge;
});

class RealtimeBridge {
  RealtimeBridge(this._ref) {
    // authStateProvider is not autoDispose, so listening for the app's lifetime
    // is safe. Session restore on the splash screen lands on the same
    // `authenticated` transition as an interactive login, so one listener covers
    // both paths. fireImmediately catches the case where auth resolved before
    // this provider was first read.
    _authSub = _ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        final was = previous?.isAuthenticated ?? false;

        if (next.isAuthenticated && !was) {
          _start(next);
        } else if (!next.isAuthenticated && was) {
          _stop();
        }
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSub;

  final List<StreamSubscription<PusherEvent>> _eventSubs = [];
  StreamSubscription<PusherConnectionState>? _connSub;

  Timer? _dashboardDebounce;
  Timer? _fallbackPoll;

  /// Panels a debounced dashboard refetch still owes.
  final Set<String> _pendingDashboardScopes = {};

  /// Bursts are common — booking an appointment notifies the patient and every
  /// admin, so several events land together. Coalescing avoids a refetch storm.
  static const Duration _dashboardDebounceWindow = Duration(milliseconds: 800);

  /// How often to poll while the socket is NOT connected. Deliberately slow:
  /// this is a safety net for a degraded connection, not a replacement for the
  /// socket, and the app was previously manual-refresh only.
  static const Duration _fallbackPollInterval = Duration(seconds: 60);

  bool _started = false;

  // ── Lifecycle ───────────────────────────────────────────────

  Future<void> _start(AuthState auth) async {
    if (_started) return;

    final userId = auth.user?.id;
    if (userId == null) {
      AppLogger.warning('[realtime] authenticated with no user id — skipping');
      return;
    }

    _started = true;

    // Seed the badge over HTTP regardless of socket health, so it is correct
    // even if real-time never comes up.
    await _ref.read(unreadNotificationCountProvider.notifier).refresh();

    if (!WebsocketConfig.isConfigured) {
      AppLogger.warning(
        '[realtime] REVERB_APP_KEY missing — real-time disabled, HTTP only',
      );
      _startFallbackPoll();
      return;
    }

    final client = _ref.read(pusherClientProvider);

    // ── Notification bell: every role, own channel ──
    _eventSubs.add(client.on(
      RealtimeChannels.user(userId),
      RealtimeEvents.notificationCreated,
      _onNotificationCreated,
    ));

    // ── A patient's own appointments, on their private channel ──
    for (final event in const [
      RealtimeEvents.appointmentCreated,
      RealtimeEvents.appointmentStatusChanged,
    ]) {
      _eventSubs.add(client.on(
        RealtimeChannels.user(userId),
        event,
        _onAppointmentChanged,
      ));
    }

    // ── Staff-only channels ──
    // Gated client-side to avoid pointless 403s, but the client treats a denial
    // as a non-fatal per-channel outcome anyway, so a role-check that disagrees
    // with the server degrades to "no events" rather than a broken connection.
    if (auth.isStaff) {
      for (final event in const [
        RealtimeEvents.appointmentCreated,
        RealtimeEvents.appointmentStatusChanged,
      ]) {
        _eventSubs.add(client.on(
          RealtimeChannels.appointments,
          event,
          _onAppointmentChanged,
        ));
      }

      _eventSubs.add(client.on(
        RealtimeChannels.dashboard,
        RealtimeEvents.dashboardStale,
        _onDashboardStale,
      ));
    }

    _connSub = client.states.listen(_onConnectionState);

    await client.connect();
  }

  void _stop() {
    _started = false;

    for (final sub in _eventSubs) {
      sub.cancel();
    }
    _eventSubs.clear();

    _connSub?.cancel();
    _connSub = null;

    _dashboardDebounce?.cancel();
    _dashboardDebounce = null;
    _pendingDashboardScopes.clear();

    _fallbackPoll?.cancel();
    _fallbackPoll = null;

    // The next user must not inherit this user's subscriptions or badge.
    _ref.read(unreadNotificationCountProvider.notifier).reset();
    _ref.read(pusherClientProvider).disconnect();
  }

  void dispose() {
    _stop();
    _authSub.close();
  }

  // ── Connection state ────────────────────────────────────────

  void _onConnectionState(PusherConnectionState state) {
    AppLogger.debug('[realtime] connection state: ${state.name}');

    if (state.isLive) {
      _fallbackPoll?.cancel();
      _fallbackPoll = null;
      // Reverb keeps no history, so everything sent while we were away is gone
      // for good. Resyncing here is a correctness requirement, not a nicety —
      // without it a user who tabs away over a blip keeps a stale badge.
      _resync();
    } else {
      _startFallbackPoll();
    }
  }

  void _startFallbackPoll() {
    if (_fallbackPoll != null) return;

    _fallbackPoll = Timer.periodic(_fallbackPollInterval, (_) {
      if (!_started) return;
      AppLogger.debug('[realtime] fallback poll (socket degraded)');
      _resync();
    });
  }

  /// Re-reads what the socket would otherwise have pushed.
  ///
  /// Only the badge and the dashboard: appointment lists are page-scoped and
  /// already have their own refresh affordances, so silently refetching them
  /// under the user could fight a filter or scroll position they just set.
  void _resync() {
    _ref.read(unreadNotificationCountProvider.notifier).refresh();
    invalidateDashboard(_ref);
  }

  // ── Handlers ────────────────────────────────────────────────

  void _onNotificationCreated(PusherEvent event) {
    final count = event.data['unread_count'];
    if (count is int) {
      _ref.read(unreadNotificationCountProvider.notifier).setCount(count);
      AppLogger.debug('[realtime] unread badge set to $count');
    }

    final raw = event.data['notification'];
    if (raw is! Map) return;

    try {
      final notification =
          NotificationModel.fromJson(Map<String, dynamic>.from(raw));

      _ref
          .read(notificationListProvider.notifier)
          .prependNotification(notification);
    } catch (e) {
      // A payload the model cannot parse must not take down the socket; the
      // count above has already been applied.
      AppLogger.error('[realtime] bad notification payload', e);
    }
  }

  void _onAppointmentChanged(PusherEvent event) {
    final raw = event.data['appointment'];
    if (raw is! Map) return;

    final AppointmentModel appointment;
    try {
      appointment = AppointmentModel.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      AppLogger.error('[realtime] bad appointment payload', e);
      return;
    }

    final notifier = _ref.read(appointmentNotifierProvider.notifier);
    final existing = _ref
        .read(appointmentNotifierProvider)
        .appointments
        .any((a) => a.id == appointment.id);

    // Patch in place rather than refresh(): a full reload would discard the
    // user's paging and re-request every page they had scrolled through.
    //
    // Only insert when the appointment is already absent AND this is a create.
    // A status change for something outside the current filter or date view is
    // deliberately dropped — inserting it would show a row the active filter
    // says should not be there.
    if (existing) {
      notifier.updateAppointment(appointment);
      AppLogger.debug(
        '[realtime] patched appointment ${appointment.id} → ${appointment.status}',
      );
    } else if (event.event == RealtimeEvents.appointmentCreated) {
      notifier.addAppointment(appointment);
      AppLogger.debug('[realtime] inserted appointment ${appointment.id}');
    } else {
      AppLogger.debug(
        '[realtime] ignored ${event.event} for appointment '
        '${appointment.id} — outside the loaded list',
      );
    }
  }

  void _onDashboardStale(PusherEvent event) {
    final scopes = event.data['scopes'];

    if (scopes is List) {
      _pendingDashboardScopes.addAll(scopes.map((s) => s.toString()));
    } else {
      // No scopes named — refetch everything.
      _pendingDashboardScopes.addAll(const [
        DashboardScope.stats,
        DashboardScope.schedule,
        DashboardScope.activity,
      ]);
    }

    _dashboardDebounce?.cancel();
    _dashboardDebounce = Timer(_dashboardDebounceWindow, () {
      final scopes = Set<String>.from(_pendingDashboardScopes);
      _pendingDashboardScopes.clear();

      if (scopes.isEmpty) return;

      AppLogger.debug('[realtime] dashboard refetch: ${scopes.join(",")}');
      invalidateDashboard(_ref, scopes: scopes);
    });
  }
}
