abstract class Failure {
  final String message;
  final String code;

  Failure({required this.message, required this.code});

  /// Without this, string interpolation of a thrown failure renders
  /// "Instance of 'ApiFailure'" — which is what users used to see in
  /// snackbars. Prefer `describeError()` for anything user-facing; this is
  /// the safety net for the interpolation sites we miss.
  @override
  String toString() => message;
}

class ApiFailure extends Failure {
  final int? statusCode;

  /// Laravel's 422 validation bag as {field: first message}. Empty for
  /// non-validation failures. Lets forms place server errors inline on the
  /// exact field instead of one generic snackbar.
  final Map<String, String> fieldErrors;

  ApiFailure({
    required String message,
    required String code,
    this.statusCode,
    this.fieldErrors = const {},
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  CacheFailure({required String message})
      : super(message: message, code: 'CACHE_FAILURE');
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message})
      : super(message: message, code: 'NETWORK_FAILURE');
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure({required String message})
      : super(message: message, code: 'AUTH_FAILURE');
}
