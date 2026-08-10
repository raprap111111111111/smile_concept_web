import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  /// Flip to true only when you need to inspect payloads.
  /// Default false to keep the VS Code debugger from crashing.
  static const bool _logBodies = false;

  static const int _maxBodyChars = 200;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.info('→ ${options.method} ${options.path}');
    if (_logBodies) {
      AppLogger.debug('  headers=${_sanitize(options.headers)}');
      if (options.data != null) {
        AppLogger.debug('  body=${_short(options.data)}');
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    AppLogger.info(
      '← ${response.statusCode} ${response.requestOptions.path}',
    );
    if (_logBodies) {
      AppLogger.debug('  data=${_short(response.data)}');
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    AppLogger.error(
      '✗ ${err.response?.statusCode ?? '???'} '
      '${err.requestOptions.path} — ${err.message}',
    );
    // Errors are usually small — always log
    if (err.response?.data != null) {
      AppLogger.error('  ${_short(err.response?.data)}');
    }
    return handler.next(err);
  }

  String _short(dynamic data) {
    if (data == null) return 'null';
    final s = data.toString();
    return s.length <= _maxBodyChars
        ? s
        : '${s.substring(0, _maxBodyChars)}… [+${s.length - _maxBodyChars}]';
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> headers) {
    final out = Map<String, dynamic>.from(headers);
    for (final k in const ['Authorization', 'authorization', 'Cookie']) {
      if (out.containsKey(k)) out[k] = '***';
    }
    return out;
  }
}