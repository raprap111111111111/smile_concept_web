// lib/data/datasources/remote/treatment_plan_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../models/treatment/treatment_plan_model.dart';

class TreatmentPlanRemoteDataSource {
  final Dio dio;
  TreatmentPlanRemoteDataSource({required this.dio});

  // ── GET list ───────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchTreatmentPlans({
    int page = 1,
    int? patientId,
    int? doctorId,
    String? status,
  }) async {
    final response = await dio.get(
      '/treatment-plans',
      queryParameters: {
        'page': page,
        if (patientId != null) 'user_id': patientId,
        if (doctorId != null) 'doctor_id': doctorId,
        if (status != null) 'status': status,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── GET single ─────────────────────────────────────────────
  Future<TreatmentPlanModel> fetchTreatmentPlanById(int id) async {
    final response = await dio.get('/treatment-plans/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return TreatmentPlanModel.fromJson(data);
  }

  // ── POST create ────────────────────────────────────────────
  Future<TreatmentPlanModel> createTreatmentPlan({
    required int userId,
    required int doctorId,
    required String name,
    required List<Map<String, dynamic>> items,
    String status = 'proposed',
    String? notes,
  }) async {
    final response = await dio.post(
      '/treatment-plans',
      data: {
        'user_id': userId,
        'doctor_id': doctorId,
        'name': name,
        'status': status,
        'items': items,
        if (notes != null) 'notes': notes,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return TreatmentPlanModel.fromJson(data);
  }

  // ── PUT update ─────────────────────────────────────────────
  Future<TreatmentPlanModel> updateTreatmentPlan({
    required int id,
    String? name,
    String? status,
    String? notes,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await dio.put(
      '/treatment-plans/$id',
      data: {
        if (name != null) 'name': name,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        if (items != null) 'items': items,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return TreatmentPlanModel.fromJson(data);
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<void> deleteTreatmentPlan(int id) async {
    await dio.delete('/treatment-plans/$id');
  }

  // ── PATCH change status ────────────────────────────────────
  Future<TreatmentPlanModel> changeStatus({
    required int id,
    required String status,
    String? reason,
  }) async {
    final response = await dio.patch(
      '/treatment-plans/$id/status',
      data: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return TreatmentPlanModel.fromJson(data);
  }
}
