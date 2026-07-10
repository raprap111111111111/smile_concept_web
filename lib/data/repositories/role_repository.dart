import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository(ref.watch(dioProvider));
});

final rolesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(roleRepositoryProvider);
  return repo.getRoles();
});

class RoleRepository {
  final Dio dio;

  RoleRepository(this.dio);

  Future<List<Map<String, dynamic>>> getRoles({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '/roles',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          'page': page,
          'limit': limit,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      List rawList;

      if (data is Map && data['records'] is List) {
        rawList = data['records'] as List;
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }

      return rawList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to load roles'),
        code: 'ROLES_FETCH_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '/roles',
        data: data,
      );

      return _extractDataMap(response);
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to create role'),
        code: 'ROLE_CREATE_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> updateRole(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/roles/$id',
        data: data,
      );

      return _extractDataMap(response);
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to update role'),
        code: 'ROLE_UPDATE_ERROR',
      );
    }
  }

  Future<void> deleteRole(int id) async {
    try {
      await dio.delete('/roles/$id');
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to delete role'),
        code: 'ROLE_DELETE_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> syncPermissions(
    int roleId,
    List<String> permissions,
  ) async {
    try {
      final response = await dio.post(
        '/roles/$roleId/permissions/sync',
        data: {
          'permissions': permissions,
        },
      );

      return _extractDataMap(response);
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to sync permissions'),
        code: 'ROLE_SYNC_PERMISSIONS_ERROR',
      );
    }
  }

  Map<String, dynamic> _extractDataMap(Response response) {
    final body = response.data as Map<String, dynamic>;
    final rawData = body['data'] ?? body;

    return Map<String, dynamic>.from(rawData as Map);
  }

  String _extractMessage(
    DioException e, {
    required String fallback,
  }) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }

        return first.toString();
      }

      return data['message']?.toString() ?? fallback;
    }

    return e.message ?? fallback;
  }

  Future<Map<String, dynamic>> getRole(int id) async {
    try {
      final response = await dio.get('/roles/$id');

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] ?? body;

      return Map<String, dynamic>.from(rawData as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to load role'),
        code: 'ROLE_FETCH_ERROR',
      );
    }
  }
}
