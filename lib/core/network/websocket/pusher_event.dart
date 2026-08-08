// lib/core/network/websocket/pusher_event.dart

import 'dart:convert';

/// One decoded frame from the Reverb socket.
class PusherEvent {
  /// Event name. Application events arrive under their `broadcastAs()` name
  /// with no prefix (e.g. `notification.created`); protocol frames use the
  /// `pusher:` / `pusher_internal:` prefixes.
  final String event;

  /// Wire channel name, including the `private-` prefix. Null on
  /// connection-level frames such as `pusher:connection_established`.
  final String? channel;

  /// Decoded payload.
  final Map<String, dynamic> data;

  const PusherEvent({
    required this.event,
    required this.data,
    this.channel,
  });

  /// Parses a raw text frame.
  ///
  /// Pusher double-encodes `data`: the frame is JSON, and `data` is a JSON
  /// *string* nested inside it, so it needs a second decode. Some frames send
  /// `data` as a bare object instead, and `pusher:pong` omits it entirely —
  /// all three shapes have to be tolerated.
  static PusherEvent? tryParse(String raw) {
    final Object? outer = jsonDecode(raw);

    if (outer is! Map<String, dynamic>) return null;

    final event = outer['event']?.toString();
    if (event == null) return null;

    return PusherEvent(
      event: event,
      channel: outer['channel']?.toString(),
      data: _decodeData(outer['data']),
    );
  }

  static Map<String, dynamic> _decodeData(Object? value) {
    if (value == null) return const {};

    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    if (value is String) {
      if (value.isEmpty) return const {};
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return const {};
      }
    }

    return const {};
  }

  bool get isProtocol =>
      event.startsWith('pusher:') || event.startsWith('pusher_internal:');

  @override
  String toString() => 'PusherEvent($event'
      '${channel != null ? ' on $channel' : ''}, '
      '${data.keys.join(",")})';
}
