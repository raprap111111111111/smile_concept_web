// lib/data/repositories/auth_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/user_model.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/errors/failures.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  Future<LoginResponse> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _remoteDataSource.login(request);

      // Save tokens FIRST so getProfile can use them
      await Future.wait([
        _secureStorage.saveToken(response.accessToken),
        _secureStorage.saveRefreshToken(response.refreshToken),
      ]);

      print('✅ Tokens saved');

      // If login didn't return user, fetch it now
      if (response.user == null) {
        print('📡 Login didn\'t include user — fetching /profile');
        final user = await _remoteDataSource.getProfile();
        return LoginResponse(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          user: user,
        );
      }

      return response;
    } catch (e) {
      print('Login failed: $e');
      throw ApiFailure(message: e.toString(), code: 'LOGIN_FAILURE');
    }
  }

  Future<LoginResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );

      await Future.wait([
        _secureStorage.saveToken(response.accessToken),
        _secureStorage.saveRefreshToken(response.refreshToken),
      ]);

      return response;
    } catch (e) {
      throw ApiFailure(message: e.toString(), code: 'REGISTER_FAILURE');
    }
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await clearSession();
    }
  }

  // ✅ Calls GET /profile (matches your Postman + Laravel setup)
  Future<UserModel> getProfile() async {
    try {
      final user = await _remoteDataSource.getProfile();
      print('✅ Profile fetched: ${user.name}');
      return user;
    } catch (e) {
      print('getProfile failed: $e');
      throw ApiFailure(
        message: e.toString(),
        code: 'PROFILE_FETCH_FAILURE',
      );
    }
  }

  Future<bool> hasValidSession() => _secureStorage.hasValidSession();
  Future<String?> getToken() => _secureStorage.getToken();
  Future<void> clearSession() => _secureStorage.clearAll();
}
