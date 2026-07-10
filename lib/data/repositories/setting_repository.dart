import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';

final settingRepositoryProvider = Provider<SettingRepository>((ref) {
  return SettingRepository(ref.watch(dioProvider));
});

final settingsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  return repo.getSettings();
});

class SettingRepository {
  final Dio dio;

  SettingRepository(this.dio);

  Future<List<Map<String, dynamic>>> getSettings({
    String? group,
    bool? isPublic,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await dio.get(
        '/settings',
        queryParameters: {
          if (group != null && group.trim().isNotEmpty) 'group': group.trim(),
          if (isPublic != null) 'is_public': isPublic ? 1 : 0,
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
        message: _extractMessage(e, fallback: 'Failed to load settings'),
        code: 'SETTINGS_FETCH_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> getSetting(String key) async {
    try {
      final response = await dio.get('/settings/$key');

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] ?? body;

      return Map<String, dynamic>.from(rawData as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to load setting'),
        code: 'SETTING_FETCH_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> updateSetting(
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/settings/$key',
        data: data,
      );

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] ?? body;

      return Map<String, dynamic>.from(rawData as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to update setting'),
        code: 'SETTING_UPDATE_ERROR',
      );
    }
  }

  Future<List<Map<String, dynamic>>> bulkUpdateSettings(
    List<Map<String, dynamic>> settings,
  ) async {
    try {
      final response = await dio.post(
        '/settings/bulk-update',
        data: {
          'settings': settings,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      if (data is List) {
        return data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw ApiFailure(
        message: _extractMessage(e, fallback: 'Failed to update settings'),
        code: 'SETTINGS_BULK_UPDATE_ERROR',
      );
    }
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
}