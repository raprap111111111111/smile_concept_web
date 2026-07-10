// lib/data/datasources/remote/auth_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/login_response.dart';
import '../../models/auth/user_model.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/auth/login',
      data: request.toJson(),
    );

    return LoginResponse.fromJson(response.data['data']);
  }

  Future<LoginResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final fullName = '$firstName $lastName'.trim();

    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': fullName,
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
        if (phone != null && phone.trim().isNotEmpty)
          'phone': phone.trim(),
      },
    );

    return LoginResponse.fromJson(response.data['data']);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // ignore
    }
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('/profile');

    print('📡 Profile Response: ${response.data}');

    final data = response.data['data'] ?? response.data;

    return UserModel.fromJson(data as Map<String, dynamic>);
  }
}