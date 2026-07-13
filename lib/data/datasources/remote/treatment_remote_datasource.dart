// lib/data/datasources/remote/treatment_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../models/treatment/treatment_model.dart';

class TreatmentRemoteDataSource {
  final Dio dio;
  TreatmentRemoteDataSource({required this.dio});

  // ── GET paginated list ─────────────────────────────────────
  Future<Map<String, dynamic>> fetchTreatments({
    int page = 1,
    bool? isActive,
    String? search,
  }) async {
    final response = await dio.get(
      '/treatments',
      queryParameters: {
        'page': page,
        if (isActive != null) 'is_active': isActive ? 1 : 0,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── GET single ─────────────────────────────────────────────
  Future<TreatmentModel> fetchTreatmentById(int id) async {
    final response = await dio.get('/treatments/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return TreatmentModel.fromJson(data);
  }

  // ── POST create ────────────────────────────────────────────
  Future<TreatmentModel> createTreatment({
    required String name,
    required double price,
    String? description,
    int estimatedDurationMinutes = 30,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        '/treatments',
        data: {
          'name':                       name,
          'price':                      price,
          if (description != null)
            'description':              description,
          'estimated_duration_minutes': estimatedDurationMinutes,
          'is_active':                  isActive,
        },
      );
      final data =
          response.data['data'] as Map<String, dynamic>;
      return TreatmentModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to create treatment',
      );
    }
  }

  // ── PUT update ─────────────────────────────────────────────
  Future<TreatmentModel> updateTreatment({
    required int id,
    String? name,
    double? price,
    String? description,
    int? estimatedDurationMinutes,
    bool? isActive,
  }) async {
    try {
      final response = await dio.put(
        '/treatments/$id',
        data: {
          if (name != null) 'name': name,
          if (price != null) 'price': price,
          if (description != null) 'description': description,
          if (estimatedDurationMinutes != null)
            'estimated_duration_minutes':
                estimatedDurationMinutes,
          if (isActive != null) 'is_active': isActive,
        },
      );
      final data =
          response.data['data'] as Map<String, dynamic>;
      return TreatmentModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to update treatment',
      );
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<void> deleteTreatment(int id) async {
    try {
      await dio.delete('/treatments/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to delete treatment',
      );
    }
  }
}