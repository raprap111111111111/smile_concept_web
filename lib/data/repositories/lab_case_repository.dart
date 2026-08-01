// lib/data/repositories/lab_case_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smile_concept_web/core/network/dio_client.dart';
import 'package:smile_concept_web/data/models/lab_case/lab_case_model.dart';

class LabCaseRepository {
  final Dio _dio;

  LabCaseRepository(this._dio);

  Future<LabCasePaginatedResponse> getAll({
    Map<String, dynamic>? params,
  }) async {
    final response = await _dio.get(
      '/lab-cases',
      queryParameters: params,
    );
    _assertSuccess(response);
    return LabCasePaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<LabCaseModel> getOne(int id) async {
    final response = await _dio.get('/lab-cases/$id');
    _assertSuccess(response);
    final data = (response.data as Map<String, dynamic>)['data'];
    return LabCaseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<LabCaseModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post('/lab-cases', data: body);
    _assertSuccess(response);
    final data = (response.data as Map<String, dynamic>)['data'];
    return LabCaseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<LabCaseModel> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.put('/lab-cases/$id', data: body);
    _assertSuccess(response);
    final data = (response.data as Map<String, dynamic>)['data'];
    return LabCaseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final response = await _dio.delete('/lab-cases/$id');
    _assertSuccess(response);
  }

  void _assertSuccess(Response response) {
    final body = response.data as Map<String, dynamic>?;
    if (body == null || body['success'] != true) {
      throw Exception(
        body?['message'] as String? ?? 'Unexpected server response.',
      );
    }
  }
}

// ── Riverpod provider ────────────────────────────────────────────────────────
// NOTE: Replace `dioProvider` with the actual provider name exported from
// lib/core/network/dio_client.dart if it's different.

final labCaseRepositoryProvider = Provider<LabCaseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LabCaseRepository(dio);
});