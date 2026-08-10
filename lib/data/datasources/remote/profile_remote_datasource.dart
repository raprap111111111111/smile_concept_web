// lib/data/datasources/remote/profile_remote_datasource.dart

import 'dart:typed_data'; // ✅ ADD THIS
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../models/profile/patient_profile_model.dart';
import '../../models/profile/profile_model.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

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
  /// Status handling now lives in `describeError`. It keeps the guard this
  /// version had — a non-Map body is never indexed — but reports it as a plain
  /// sentence rather than pasting the HTML or PHP warning into the UI.
  Exception _handleError(DioException e) => Exception(
        describeError(e, fallback: "We couldn't update your profile. Please "
            'try again.'),
      );
}