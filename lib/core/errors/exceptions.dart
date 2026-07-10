class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    required this.code,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class LocalStorageException implements Exception {
  final String message;
  const LocalStorageException(this.message);
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
}