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
        exception = ApiException(
          message: responseData is Map<String, dynamic>
              ? responseData['message']?.toString() ?? 'Server error'
              : 'Server error',
          code: responseData is Map<String, dynamic>
              ? responseData['code']?.toString() ?? 'SERVER_ERROR'
              : 'SERVER_ERROR',
          statusCode: err.response?.statusCode,
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
        exception = const ApiException(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        );
    }

    // 🔑 Reject with our custom exception so services can catch it cleanly
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }
}
