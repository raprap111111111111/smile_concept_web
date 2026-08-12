import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../../utils/logger.dart';

/// [LoggingInterceptor] provides structured observability for network requests.
/// 
/// It follows senior architectural patterns:
/// 1. Zero overhead in production (via kDebugMode).
/// 2. Prevents PII/Credential leakage via [ _sensitiveHeaders ].
/// 3. Prevents memory pressure by truncating large payloads.
class LoggingInterceptor extends Interceptor {
  /// Headers that should NEVER be logged in any environment.
  static const Set<String> _sensitiveHeaders = {
    'authorization',
    'cookie',
    'x-api-key',
    'token',
  };

  /// Maximum characters to log for request/response bodies to prevent 
  /// console lag and memory spikes when handling large JSONs.
  static const int _maxBodyLength = 1000;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only execute logging logic in debug mode to ensure zero production overhead.
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      
      AppLogger.info('🚀 [NETWORK] $timestamp | ${options.method} ${options.path}');
      
      // Log headers and body only if they exist
      _logRequestDetails(options);
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      AppLogger.info('✅ [NETWORK] ${response.statusCode} | ${response.requestOptions.path}');
      _logResponseDetails(response);
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      final statusCode = err.response?.statusCode;
      final path = err.requestOptions.path;
      
      AppLogger.error('❌ [NETWORK] $statusCode | $path');
      AppLogger.error('   Message: ${err.message}');
      
      if (err.response?.data != null) {
        AppLogger.error('   Error Payload: ${_truncate(err.response?.data)}');
      }
    }
    return handler.next(err);
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  void _logRequestDetails(RequestOptions options) {
    final sanitizedHeaders = _sanitizeHeaders(options.headers);
    AppLogger.debug('   Headers: $sanitizedHeaders');

    if (options.data != null) {
      AppLogger.debug('   Body: ${_truncate(options.data)}');
    }
  }

  void _logResponseDetails(Response response) {
    if (response.data != null) {
      AppLogger.debug('   Data: ${_truncate(response.data)}');
    }
  }

  /// Truncates data to avoid crashing the IDE console with massive JSON strings.
  String _truncate(dynamic data) {
    if (data == null) return 'null';
    
    // If it's already a string, truncate it. 
    // If it's a Map/List, convert to string first.
    final String content = data is String ? data : data.toString();
    
    if (content.length <= _maxBodyLength) return content;
    
    return '${content.substring(0, _maxBodyLength)}... [Truncated ${content.length - _maxBodyLength} chars]';
  }

  /// Removes sensitive information from headers to comply with security standards (GDPR/HIPAA).
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      final lowerKey = key.toLowerCase();
      return MapEntry(
        key,
        _sensitiveHeaders.contains(lowerKey) ? '********' : value,
      );
    });
  }
}