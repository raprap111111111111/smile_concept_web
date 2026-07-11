// lib/data/datasources/remote/profile_remote_datasource.dart

import 'dart:typed_data'; // ✅ ADD THIS
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../models/profile/patient_profile_model.dart';
import '../../models/profile/profile_model.dart';

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioProvider));
});

class ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSource(this._dio);

  // ─── GET /users/me ────────────────────────────────────────────────
  Future<ProfileModel> getMyProfile() async {
    try {
      final response = await _dio.get(ApiConfig.me);
      final data = response.data['data'] as Map<String, dynamic>;
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── PUT /users/:id (basic info only, no photo) ────────────────────
  Future<ProfileModel> updateProfile({
    required int userId,
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.users}/$userId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── POST /users/:id (with photo — works on WEB + NATIVE) ─────────
  Future<ProfileModel> updateProfileWithPhoto({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? photoFilePath,          // Native: file path
    Uint8List? photoBytes,          // ✅ Web: bytes
    String? photoFileName,          // ✅ Web: filename
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        '_method': 'PUT', // Laravel form-data workaround for PUT
      };

      // ✅ Handle photo — different for web vs native
      if (photoBytes != null) {
        // Web: use bytes
        formDataMap['photo'] = MultipartFile.fromBytes(
          photoBytes,
          filename: photoFileName ?? 'profile.jpg',
        );
      } else if (photoFilePath != null) {
        // Native (mobile/desktop): use file path
        formDataMap['photo'] = await MultipartFile.fromFile(
          photoFilePath,
          filename: photoFilePath.split('/').last,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        '${ApiConfig.users}/$userId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── PUT /patient-profiles/:id ────────────────────────────────────
  Future<ProfileModel> updatePatientProfile({
    required int patientProfileId,
    required PatientProfileModel patientProfile,
  }) async {
    try {
      await _dio.put(
        '${ApiConfig.patientProfiles}/$patientProfileId',
        data: patientProfile.toUpdateJson(),
      );
      return getMyProfile();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Error Handler ────────────────────────────────────────────────
  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] ??
        e.message ??
        'Unknown error occurred';

    switch (statusCode) {
      case 401:
        return Exception('Unauthorized: $message');
      case 403:
        return Exception('Forbidden: $message');
      case 404:
        return Exception('Not found: $message');
      case 422:
        final errors = e.response?.data?['errors'];
        if (errors != null) {
          final firstError = (errors as Map).values.first;
          return Exception(
            firstError is List ? firstError.first : firstError.toString(),
          );
        }
        return Exception(message);
      default:
        return Exception(message);
    }
  }
}