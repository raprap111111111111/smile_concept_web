import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

class PermissionRepository {
  final Dio dio;

  PermissionRepository(this.dio);

  /// GET /permissions/grouped
  ///
  /// Returns:
  /// {
  ///   "user":        [ {id: 1, name: "user.viewAny"}, ... ],
  ///   "role":        [ ... ],
  ///   "appointment": [ ... ],
  /// }
  Future<Map<String, List<Map<String, dynamic>>>> getGroupedPermissions() async {
    try {
      final response = await dio.get('/permissions/grouped');

      final data = response.data['data'] as Map<String, dynamic>;

      return data.map((key, value) {
        final list = (value as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return MapEntry(key, list);
      });
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to load permissions'),
        code: 'PERMISSIONS_FETCH_ERROR',
        statusCode: errorStatusCode(e),
      );
    }
  }
}

/// Providers
final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PermissionRepository(ref.watch(dioProvider));
});

final permissionsGroupedProvider = FutureProvider.autoDispose<
    Map<String, List<Map<String, dynamic>>>>((ref) async {
  final repo = ref.watch(permissionRepositoryProvider);
  return repo.getGroupedPermissions();
});