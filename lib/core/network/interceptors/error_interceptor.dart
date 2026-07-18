import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    late ApiException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = const ApiException(
          message: 'Connection timeout. Please try again.',
          code: 'TIMEOUT_ERROR',
        );
        break;
      case DioExceptionType.badResponse:
        final responseData = err.response?.data;
        final status = err.response?.statusCode;
        // A non-Map body means the server returned something that isn't our
        // JSON envelope — a PHP warning/HTML error page, typically. Surface a
        // snippet of it instead of a generic string, or the real cause is lost.
        exception = ApiException(
          message: responseData is Map<String, dynamic>
              ? responseData['message']?.toString() ?? 'Server error ($status)'
              : 'Server error ($status): ${_snippet(responseData)}',
          code: responseData is Map<String, dynamic>
              ? responseData['code']?.toString() ?? 'SERVER_ERROR'
              : 'SERVER_ERROR',
          statusCode: status,
        );
        break;
      case DioExceptionType.connectionError:
        exception = const ApiException(
          message:
              'Cannot reach the API. Check the Laravel URL, port, and CORS settings.',
          code: 'API_CONNECTION_ERROR',
        );
        break;
      default:
        exception = ApiException(
          message: 'An unexpected error occurred'
              '${err.message != null ? ': ${err.message}' : ''}',
          code: 'UNKNOWN_ERROR',
        );
    }

    // 🔑 Reject with our custom exception so services can catch it cleanly.
    // `message` must be forwarded — without it `err.message` is null for every
    // downstream handler, which collapses distinct failures into one string.
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
        message: exception.message,
      ),
    );
  }

  /// First line of a non-JSON error body, truncated for display.
  static String _snippet(dynamic body) {
    if (body == null) return 'empty response body';
    final text = body.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return 'empty response body';
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }
}
