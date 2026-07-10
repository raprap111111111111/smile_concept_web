import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/auth/user_model.dart';

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  // ═══════════════════════════════════════════
  // GET CURRENT USER
  // ═══════════════════════════════════════════
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get('/users/me');

    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data == null) {
      throw Exception('Failed to load current user');
    }

    return apiResponse.data!;
  }

  // ═══════════════════════════════════════════
  // GET STAFF USERS (exclude patients)
  // ═══════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getStaffUsers({
    String? search,
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/users', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.isNotEmpty) 'role': role,
        'exclude_role': 'patient', // 🔑 hide patients
        'page': page,
        'limit': limit,
      });

      final body = response.data;
      final data = body['data'];

      List rawList;
      if (data is Map && data['records'] is List) {
        rawList = data['records'];
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }

      return rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.response?.data?['message'] ?? 'Failed to load users',
        code: 'USERS_FETCH_ERROR',
      );
    }
  }

  // ═══════════════════════════════════════════
  // CREATE
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/users', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.response?.data?['message'] ?? 'Failed to create user',
        code: 'USER_CREATE_ERROR',
      );
    }
  }

  // ═══════════════════════════════════════════
  // UPDATE
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>> updateUser(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/users/$id', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.response?.data?['message'] ?? 'Failed to update user',
        code: 'USER_UPDATE_ERROR',
      );
    }
  }

  // ═══════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════
  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.response?.data?['message'] ?? 'Failed to delete user',
        code: 'USER_DELETE_ERROR',
      );
    }
  }
}

// ═══════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

final staffUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getStaffUsers();
});