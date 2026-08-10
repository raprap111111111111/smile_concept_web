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
          message: 'The server took too long to respond. Please try again.',
          code: 'TIMEOUT_ERROR',
        );
        break;
      case DioExceptionType.badResponse:
        exception = _fromResponse(err);
        break;
      case DioExceptionType.connectionError:
        exception = const ApiException(
          message: 'Cannot reach the server. Check your internet connection '
              'and try again.',
          code: 'API_CONNECTION_ERROR',
        );
        break;
      case DioExceptionType.cancel:
        exception = const ApiException(
          message: 'The request was cancelled.',
          code: 'REQUEST_CANCELLED',
        );
        break;
      default:
        // `err.message` here is Dart-level diagnostics ("HttpException",
        // "type 'Null' is not a subtype of..."). It goes to the log, not the
        // user; `describeError` decides what the user sees.
        exception = ApiException(
          message: 'Something went wrong. Please try again.',
          code: 'UNKNOWN_ERROR',
          originalError: err.message,
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

  /// Builds the exception for a response that arrived but carried an error
  /// status. The status code is always preserved so `describeError` can pick
  /// the right wording even when the body is unusable.
  static ApiException _fromResponse(DioException err) {
    final data = err.response?.data;
    final status = err.response?.statusCode;

    if (data is Map<String, dynamic>) {
      // Laravel's 422 body puts the actionable text under `errors`, keyed by
      // field; the top-level `message` is usually "The given data was invalid."
      final validation = _validationMessage(data);
      final message = validation ??
          data['message']?.toString() ??
          _defaultForStatus(status);

      return ApiException(
        message: message,
        code: data['code']?.toString() ?? 'SERVER_ERROR',
        statusCode: status,
        originalError: data,
      );
    }

    // A non-Map body means the server returned something that isn't our JSON
    // envelope — a PHP warning or HTML error page, typically. The snippet is
    // kept on `originalError` for logs; the user gets a plain sentence.
    return ApiException(
      message: _defaultForStatus(status),
      code: 'SERVER_ERROR',
      statusCode: status,
      originalError: _snippet(data),
    );
  }

  static String? _validationMessage(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is! Map || errors.isEmpty) return null;

    final messages = <String>[];
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        messages.addAll(value.whereType<String>());
      } else if (value is String) {
        messages.add(value);
      }
    }
    if (messages.isEmpty) return null;
    if (messages.length <= 2) return messages.join(' ');
    return '${messages.take(2).join(' ')} (+${messages.length - 2} more)';
  }

  static String _defaultForStatus(int? status) {
    if (status == null) return 'Something went wrong. Please try again.';
    if (status >= 500) {
      return 'Something went wrong on our end. Please try again in a moment.';
    }
    switch (status) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return "You don't have permission to do this. Ask an administrator to "
            'grant you access.';
      case 404:
        return "We couldn't find that record. It may have been deleted by "
            'someone else.';
      case 413:
        return 'That file is too large to upload.';
      case 422:
        return 'Some details are missing or invalid. Check the highlighted '
            'fields.';
      case 429:
        return "You're doing that too quickly. Wait a moment and try again.";
      default:
        return "That request couldn't be completed. Please try again.";
    }
  }

  /// First line of a non-JSON error body, truncated — kept for diagnostics.
  static String _snippet(dynamic body) {
    if (body == null) return 'empty response body';
    final text = body.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return 'empty response body';
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }
}
