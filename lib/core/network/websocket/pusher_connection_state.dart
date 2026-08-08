// lib/core/network/websocket/pusher_connection_state.dart

/// Lifecycle of the single app-wide Reverb socket.
enum PusherConnectionState {
  /// Never connected, or torn down after logout.
  idle,

  /// Handshake in flight, no socket_id yet.
  connecting,

  /// `pusher:connection_established` received and socket_id captured.
  connected,

  /// Dropped, backoff timer armed, will retry.
  reconnecting,

  /// Still retrying, but has failed enough times that the UI should say so.
  unavailable,

  /// Unrecoverable — a fatal Pusher error (4000-4099) or a 401 from
  /// /broadcasting/auth. No further retries will be attempted.
  failed;

  bool get isLive => this == PusherConnectionState.connected;

  /// Whether the UI should surface a degraded-connection indicator.
  bool get isDegraded =>
      this == PusherConnectionState.unavailable ||
      this == PusherConnectionState.failed;

  /// Whether a fallback poll should be covering for the socket.
  bool get needsFallback => this != PusherConnectionState.connected;
}
