// lib/data/services/patient_attachment_service.dart

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/patient_attachment/patient_attachment_model.dart';

class PatientAttachmentService {
  final Dio _dio;

  PatientAttachmentService(this._dio);

  static const String _basePath = '/patient-attachments';

  // ═══════════════════════════════════════════════════════
  // ATTACHMENTS CRUD
  // ═══════════════════════════════════════════════════════

  /// List all attachments with filters
  Future<Map<String, dynamic>> getAll({
    int page = 1,
    int perPage = 15,
    String? search,
    String? category,
    String? scanStatus,
    int? userId,
    bool? isXray,
  }) async {
    final response = await _dio.get(_basePath, queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null) 'search': search,
      if (category != null) 'category': category,
      if (scanStatus != null) 'scan_status': scanStatus,
      if (userId != null) 'user_id': userId,
      if (isXray != null) 'is_xray': isXray ? 1 : 0,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get single attachment by ID
  Future<PatientAttachment> getById(int id) async {
    final response = await _dio.get('$_basePath/$id');
    return PatientAttachment.fromJson(response.data['data']);
  }

  /// Upload attachment with real file
  Future<PatientAttachment> create({
    required int userId,
    int? appointmentId,
    required PlatformFile file,
    required String fileName,
    required String category,
    bool isXray = false,
    String? notes,
  }) async {
    // ✅ ADD THIS DEBUG
    print('📤 UPLOAD DEBUG:');
    print('   user_id: $userId');
    print('   file_name: $fileName');
    print('   category: $category');
    print('   file: ${file.name}');

    final formData = FormData.fromMap({
      'user_id': userId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'file_name': fileName,
      'file_type': file.extension ?? 'jpg',
      'category': category,
      'is_xray': isXray ? 1 : 0,
      if (notes != null) 'notes': notes,
      'file': MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      ),
    });

    final response = await _dio.post(
      _basePath,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return PatientAttachment.fromJson(response.data['data']);
  }

  /// Delete attachment
  Future<void> delete(int id) async {
    await _dio.delete('$_basePath/$id');
  }

  // ═══════════════════════════════════════════════════════
  // PATIENT QUERIES
  // ═══════════════════════════════════════════════════════

  /// Get patients who have attachments (for folder view)
  /// Endpoint: GET /api/v1/patient-attachments/patients
  Future<Map<String, dynamic>> getPatientsWithAttachments({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final response = await _dio.get(
      '$_basePath/patients',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get attachments for a specific patient
  /// Endpoint: GET /api/v1/patient-attachments/patients/{userId}
  Future<Map<String, dynamic>> getByPatientId({
    required int userId,
    int page = 1,
    int perPage = 15,
    String? category,
    String? scanStatus,
    String? search,
  }) async {
    final response = await _dio.get(
      '$_basePath/patients/$userId',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null) 'category': category,
        if (scanStatus != null) 'scan_status': scanStatus,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════════════
  // ✅ ALL USERS (for patient selector in upload form)
  // ═══════════════════════════════════════════════════════

  /// Get all users/patients for the selector dropdown
  /// Endpoint: GET /api/v1/users
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int perPage = 100,
    String? search,
  }) async {
    final response = await _dio.get(
      '/users',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
