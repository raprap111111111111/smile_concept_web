// lib/core/network/websocket/realtime_channels.dart

/// Wire channel names.
///
/// The `private-` prefix belongs on the wire only. routes/channels.php
/// registers the *unprefixed* name (`clinic.appointments`), while clients
/// subscribe to `private-clinic.appointments`. Mixing the two up produces a 403
/// from /broadcasting/auth with no other symptom, so the prefix is applied in
/// exactly one place: here.
class RealtimeChannels {
  const RealtimeChannels._();

  /// Per-user channel: notification bell, and a patient's own appointments.
  /// Matches Laravel's own naming for a User model.
  static String user(int userId) => 'private-App.Models.User.$userId';

  /// Shared staff feed. Authorized by User::isStaff().
  static const String appointments = 'private-clinic.appointments';

  /// Dashboard counters. Authorized by the `dashboard.view` permission.
  static const String dashboard = 'private-clinic.dashboard';
}

/// Event names, matching each event's `broadcastAs()` on the Laravel side.
/// These arrive unprefixed.
class RealtimeEvents {
  const RealtimeEvents._();

  static const String notificationCreated = 'notification.created';
  static const String appointmentCreated = 'appointment.created';
  static const String appointmentStatusChanged = 'appointment.status_changed';
  static const String dashboardStale = 'dashboard.stale';
}
