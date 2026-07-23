// lib/data/services/patient_folder_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// ✅ Dedicated service for patient folder operations
class PatientFolderService {
  final Dio _dio;

  PatientFolderService(this._dio);

  static const String _basePath = '/patient-folders';

  /// List all patient folders (with attachment counts)
  Future<Map<String, dynamic>> listFolders({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    debugPrint('🌐 GET $_basePath');
    final response = await _dio.get(
      _basePath,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get files inside a specific patient's folder
  Future<Map<String, dynamic>> getFolderContents({
    required int userId,
    int page = 1,
    int perPage = 15,
    String? search,
    String? category,
    String? scanStatus,
    String? fileType,
    bool? isXray,
    String? orderBy,
    String? orderDir,
  }) async {
    debugPrint('🌐 GET $_basePath/$userId');
    final response = await _dio.get(
      '$_basePath/$userId',
      queryParameters: {
        'page': page,
        'limit': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null) 'category': category,
        if (scanStatus != null) 'scan_status': scanStatus,
        if (fileType != null) 'file_type': fileType,
        if (isXray != null) 'is_xray': isXray ? 1 : 0,
        if (orderBy != null) 'order_by': orderBy,
        if (orderDir != null) 'order_dir': orderDir,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}