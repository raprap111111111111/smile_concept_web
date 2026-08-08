// lib/core/network/websocket/websocket_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../config/api_config.dart';

/// Connection details for the Reverb WebSocket server.
///
/// Reverb listens on its own port (8080 by default), not the Laravel HTTP port,
/// so the socket host cannot be derived from [ApiConfig.baseUrl] — it needs its
/// own env keys. The channel-authorization endpoint *is* on the HTTP host, at
/// the web root rather than under `/api/v1`, so that one uses
/// [ApiConfig.rootUrl].
class WebsocketConfig {
  /// Pusher protocol version Reverb implements.
  static const String protocolVersion = '7';
  static const String clientName = 'dart-smile';
  static const String clientVersion = '1.0.0';

  static String get appKey => dotenv.env['REVERB_APP_KEY'] ?? '';

  static String get host => dotenv.env['REVERB_HOST'] ?? '127.0.0.1';

  static int get port => int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? 8080;

  static String get scheme => dotenv.env['REVERB_SCHEME'] ?? 'http';

  static bool get useTls => scheme == 'https';

  /// A ws:// socket opened from an https:// page is blocked as mixed content,
  /// so this must follow the HTTP scheme rather than being hardcoded.
  static String get wsScheme => useTls ? 'wss' : 'ws';

  /// Real-time is optional. With no app key the app runs HTTP-only rather than
  /// crashing, so a missing key degrades instead of breaking every screen.
  static bool get isConfigured => appKey.isNotEmpty;

  /// ws://127.0.0.1:8080/app/<key>?protocol=7&client=dart-smile&version=1.0.0
  static Uri get connectUri => Uri.parse(
        '$wsScheme://$host:$port/app/$appKey'
        '?protocol=$protocolVersion'
        '&client=$clientName'
        '&version=$clientVersion',
      );

  /// Broadcast::routes() registers this at the web root, NOT under /api/v1.
  static String get authUrl => '${ApiConfig.rootUrl}/broadcasting/auth';

  /// Redacted form for logs — never log [connectUri] directly if the key is
  /// considered sensitive in a given deployment.
  static String get describe =>
      '$wsScheme://$host:$port (key ${appKey.isEmpty ? "MISSING" : "set"})';
}
