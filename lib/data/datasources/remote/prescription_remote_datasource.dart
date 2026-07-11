// lib/data/datasources/remote/prescription_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../models/prescription/prescription_model.dart';

class PrescriptionRemoteDataSource {
  final Dio dio;

  PrescriptionRemoteDataSource({required this.dio});

  // ─── GET List ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchPrescriptions({
    int page = 1,
    int? patientId,
    int? doctorId,
  }) async {
    final response = await dio.get(
      '/prescriptions',
      queryParameters: {
        'page': page,
        if (patientId != null) 'patient_id': patientId,
        if (doctorId != null) 'doctor_id': doctorId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── GET Single ───────────────────────────────────────────
  Future<PrescriptionModel> fetchPrescriptionById(int id) async {
    final response = await dio.get('/prescriptions/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return PrescriptionModel.fromJson(data);
  }

  // ─── CREATE Prescription with Items (single request) ─────
  Future<PrescriptionModel> createPrescription({
    required int doctorId,
    required int userId,
    required List<Map<String, dynamic>> items,
    int? appointmentId,
    String? notes,
  }) async {
    final response = await dio.post(
      '/prescriptions',
      data: {
        'doctor_id': doctorId,
        'user_id': userId,
        'items': items,
        if (appointmentId != null) 'appointment_id': appointmentId,
        if (notes != null) 'notes': notes,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PrescriptionModel.fromJson(data);
  }

  // ─── DELETE Prescription ──────────────────────────────────
  Future<void> deletePrescription(int id) async {
    await dio.delete('/prescriptions/$id');
  }
}