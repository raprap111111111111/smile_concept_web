import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notification/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

/// Unread badge count.
///
/// A StateNotifier rather than a FutureProvider because the socket pushes an
/// authoritative count with every notification: the badge can be *set* instead
/// of invalidated-and-refetched, which removes the loading flicker and a round
/// trip per event. Not autoDispose — the bell sits in the topbar on every
/// authenticated screen, and the count must survive go_router transitions.
///
/// Nothing is fetched on construction; that would fire before login and 401.
/// RealtimeBridge calls [UnreadNotificationCountNotifier.refresh] once the user
/// is authenticated, and again after any socket reconnect.
final unreadNotificationCountProvider =
    StateNotifierProvider<UnreadNotificationCountNotifier, int>((ref) {
  return UnreadNotificationCountNotifier(
    ref.watch(notificationRepositoryProvider),
  );
});

class UnreadNotificationCountNotifier extends StateNotifier<int> {
  UnreadNotificationCountNotifier(this._repository) : super(0);

  final NotificationRepository _repository;

  /// Re-reads the count over HTTP. Used to seed after login and to resync after
  /// a socket outage, during which broadcasts are lost for good.
  Future<void> refresh() async {
    try {
      state = await _repository.getUnreadCount();
    } catch (_) {
      // Keep the last known value; a failed refresh should not blank the badge.
    }
  }

  /// Authoritative count from a broadcast. Setting beats incrementing: an
  /// increment drifts whenever an event is missed or several tabs are open.
  void setCount(int count) {
    if (count >= 0) state = count;
  }

  void reset() => state = 0;
}

class NotificationListState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final bool unreadOnly;

  const NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadOnly = false,
  });

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool? unreadOnly,
    bool clearError = false,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
  (ref) {
    return NotificationListNotifier(
      ref.watch(notificationRepositoryProvider),
      ref,
    );
  },
);

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationListNotifier(this._repository, this._ref)
      : super(const NotificationListState());

  Future<void> load({
    bool unreadOnly = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      unreadOnly: unreadOnly,
      clearError: true,
    );

    try {
      final notifications = await _repository.getNotifications(
        unreadOnly: unreadOnly ? true : null,
      );

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        clearError: true,
      );

      await _ref.read(unreadNotificationCountProvider.notifier).refresh();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: describeError(error),
      );
    }
  }

  Future<void> refresh() async {
    await load(unreadOnly: state.unreadOnly);
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await refresh();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    await refresh();
  }

  /// Inserts a socket-delivered notification at the top of the list without a
  /// refetch. Mirrors the local-mutator pattern on InvoiceNotifier.
  ///
  /// Ignored when the list is filtered to unread and the row arrives already
  /// read, and deduplicated by id because a reconnect resync can legitimately
  /// deliver a row the socket already pushed.
  void prependNotification(NotificationModel notification) {
    if (state.unreadOnly && notification.isRead) return;

    if (state.notifications.any((n) => n.id == notification.id)) return;

    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
  }
}