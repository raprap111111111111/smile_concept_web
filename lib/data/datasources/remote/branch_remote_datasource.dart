import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../models/branch/branch_model.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

final branchRemoteDataSourceProvider = Provider<BranchRemoteDataSource>((ref) {
  return BranchRemoteDataSource(ref.watch(dioProvider));
});

class BranchRemoteDataSource {
  final Dio _dio;

  BranchRemoteDataSource(this._dio);

  Future<List<BranchModel>> getBranches({
    String? search,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.get(
        '/branches',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'];

      List records;

      if (rawData is Map<String, dynamic>) {
        records = rawData['records'] as List? ?? [];
      } else if (rawData is List) {
        records = rawData;
      } else {
        records = [];
      }

      return records
          .map((item) => BranchModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BranchModel> createBranch(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/branches',
        data: data,
      );

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] ?? body;

      return BranchModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BranchModel> updateBranch(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/branches/$id',
        data: data,
      );

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] ?? body;

      return BranchModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBranch(int id) async {
    try {
      await _dio.delete('/branches/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Status handling now lives in `describeError`, which turns 401/403/404 into
  /// sentences instead of the "Unauthorized: <server text>" prefixes this used
  /// to emit, and reads the whole validation bag rather than one field.
  Exception _handleError(DioException e) => Exception(
        describeError(e, fallback: "That branch request didn't go through. "
            'Please try again.'),
      );
}