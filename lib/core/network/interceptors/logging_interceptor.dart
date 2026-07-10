import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    AppLogger.info('${options.method} ${options.path}');
    AppLogger.debug('Headers: ${options.headers}');
    if (options.data != null) {
      AppLogger.debug('Body: ${options.data}');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    AppLogger.info('${response.statusCode} ${response.requestOptions.path}');
    AppLogger.debug('Response: ${response.data}');
    return handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    AppLogger.error('Error: ${err.message}');
    if (err.response != null) {
      AppLogger.error('Response: ${err.response?.data}');
    }
    return handler.next(err);
  }
}