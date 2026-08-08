// lib/core/network/websocket/pusher_channel_authorizer.dart

import 'package:dio/dio.dart';

import 'websocket_config.dart';

/// Outcome of a private-channel authorization attempt.
sealed class ChannelAuthResult {
  const ChannelAuthResult();
}

/// Signature to put in the `pusher:subscribe` frame.
class ChannelAuthGranted extends ChannelAuthResult {
  final String auth;
  const ChannelAuthGranted(this.auth);
}

/// The channel closure in routes/channels.php returned false (403). Expected
/// for optional channels the current role has no business on — not an error.
class ChannelAuthDenied extends ChannelAuthResult {
  const ChannelAuthDenied();
}

/// The credential itself is no good (401). Fatal: retrying cannot help, so the
/// client must stop rather than loop against a dead token.
class ChannelAuthUnauthenticated extends ChannelAuthResult {
  const ChannelAuthUnauthenticated();
}

/// Network/server trouble. Retryable.
class ChannelAuthFailed extends ChannelAuthResult {
  final String reason;
  const ChannelAuthFailed(this.reason);
}

/// Signs private-channel subscriptions via `POST /broadcasting/auth`.
///
/// Flutter Web cannot set an `Authorization` header on a WebSocket handshake —
/// the browser `WebSocket` constructor takes only `(url, protocols)` — so the
/// token can never travel with the socket itself. Instead the server signs
/// `socket_id:channel_name` with the app secret over ordinary HTTP, and that
/// signature goes in the subscribe frame. This keeps the bearer token out of
/// the WebSocket URL, where it would otherwise land in server and proxy logs.
class PusherChannelAuthorizer {
  /// The app-wide Dio, so the Passport bearer token and every interceptor are
  /// reused rather than reimplemented.
  final Dio _dio;

  const PusherChannelAuthorizer(this._dio);

  Future<ChannelAuthResult> authorize({
    required String socketId,
    required String channelName,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        // Absolute URL — this endpoint is at the web root, so it must bypass
        // Dio's /api/v1 baseUrl.
        WebsocketConfig.authUrl,
        data: {
          'socket_id': socketId,
          'channel_name': channelName,
        },
      );

      final body = response.data;
      final auth = body is Map ? body['auth']?.toString() : null;

      if (auth == null || auth.isEmpty) {
        return const ChannelAuthFailed('auth field missing from response');
      }

      return ChannelAuthGranted(auth);
    } on DioException catch (e) {
      // A 403 body is HTML, not JSON: the exception renderer in
      // bootstrap/app.php only JSON-ifies api/* paths. Only the status matters.
      switch (e.response?.statusCode) {
        case 401:
          return const ChannelAuthUnauthenticated();
        case 403:
          return const ChannelAuthDenied();
        default:
          return ChannelAuthFailed(
            e.response?.statusCode != null
                ? 'HTTP ${e.response!.statusCode}'
                : e.message ?? 'request failed',
          );
      }
    } catch (e) {
      return ChannelAuthFailed(e.toString());
    }
  }
}
