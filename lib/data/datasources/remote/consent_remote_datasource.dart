// lib/data/datasources/remote/consent_remote_datasource.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../models/consent/consent_sign_request.dart';
import '../../models/consent/consent_template_model.dart';
import '../../models/consent/paginated_consent_result.dart';
import '../../models/consent/patient_consent_model.dart';

final consentRemoteDataSourceProvider =
    Provider<ConsentRemoteDataSource>((ref) {
  return ConsentRemoteDataSource(ref.watch(dioProvider));
});

class ConsentRemoteDataSource {
  final Dio _dio;

  ConsentRemoteDataSource(this._dio);

  /// GET /consents/templates
  Future<List<ConsentTemplateModel>> getTemplates() async {
    final response = await _dio.get('/consents/templates');
    final data = response.data['data'] as List;
    return data
        .map((e) => ConsentTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /consents
  Future<PaginatedConsentResult> getSignedConsents({
    int? userId,
    int? appointmentId,
    int? consentTemplateId,
    String? search,
    String? status,
    int offset = 0,
    int limit = 15,
  }) async {
    final response = await _dio.get('/consents', queryParameters: {
      if (userId != null) 'user_id': userId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (consentTemplateId != null) 'consent_template_id': consentTemplateId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null) 'status': status,
      'offset': offset,
      'limit': limit,
    });

    return PaginatedConsentResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// GET /consents/{id}
  Future<PatientConsentModel> getConsentById(int id) async {
    final response = await _dio.get('/consents/$id');
    return PatientConsentModel.fromJson(response.data['data']);
  }

  /// GET /consents/appointments/{id}/consents
  Future<List<PatientConsentModel>> getByAppointment(int appointmentId) async {
    final response =
        await _dio.get('/consents/appointments/$appointmentId/consents');
    final data = response.data['data'] as List;
    return data
        .map((e) => PatientConsentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /consents/sign
  Future<PatientConsentModel> sign(ConsentSignRequest request) async {
    final response = await _dio.post('/consents/sign', data: request.toJson());
    return PatientConsentModel.fromJson(response.data['data']);
  }

// ✅ AFTER — matches 'reason' => ['required'...] in VoidConsentRequest
  Future<PatientConsentModel> voidConsent(int id, String reason) async {
    final response = await _dio.post(
      '/consents/$id/void',
      data: {'reason': reason}, // ✅ fixed
    );
    return PatientConsentModel.fromJson(response.data['data']);
  }

  /// GET /consents/{id}/pdf
  Future<Uint8List> getPdfBytes(int id) async {
    final response = await _dio.get<List<int>>(
      '/consents/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}
