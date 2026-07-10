// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import '../../services/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔐 Bearer attached → ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only try refresh on 401 (token expired)
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    // Skip refresh if the failing request is the refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token — cannot refresh');
        _isRefreshing = false;
        return handler.next(err);
      }

      print('🔄 Access token expired — refreshing...');

      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final response = await refreshDio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final newAccessToken = response.data['data']['access_token'] as String;
      final newRefreshToken = response.data['data']['refresh_token'] as String;

      await _storage.saveToken(newAccessToken);
      await _storage.saveRefreshToken(newRefreshToken);

      print('✅ Refreshed — retrying original request');

      // Retry original request
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(options);

      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (e) {
      print('Token refresh failed: $e');
      _isRefreshing = false;

      // ✋ DO NOT CLEAR TOKENS HERE
      // Let the auth provider decide what to do based on the error
      return handler.next(err);
    }
  }
}