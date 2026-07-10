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
        exception = ApiException(
          message: err.response?.data?['message'] ?? 'Server error',
          code: err.response?.data?['code'] ?? 'SERVER_ERROR',
          statusCode: err.response?.statusCode,
        );
        break;
      case DioExceptionType.connectionError:
        exception = const ApiException(
          message: 'No internet connection',
          code: 'NO_INTERNET',
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