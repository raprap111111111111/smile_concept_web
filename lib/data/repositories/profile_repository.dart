// lib/data/repositories/profile_repository.dart

import 'dart:typed_data'; // ✅ ADD THIS
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/local/profile_local_datasource.dart';
import '../datasources/remote/profile_remote_datasource.dart';
import '../models/profile/patient_profile_model.dart';
import '../models/profile/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    remote: ref.watch(profileRemoteDataSourceProvider),
    local: ref.watch(profileLocalDataSourceProvider),
  );
});

class ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _local;

  ProfileRepository({
    required ProfileRemoteDataSource remote,
    required ProfileLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  Future<ProfileModel> getMyProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _local.getCachedProfile();
      if (cached != null) return cached;
    }

    try {
      final result = await _remote.getMyProfile();
      await _local.cacheProfile(result);
      return result;
    } catch (e) {
      final cached = await _local.getCachedProfile();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<ProfileModel> updateProfile({
    required int userId,
    String? name,
    String? email,
    String? phone,
  }) async {
    final result = await _remote.updateProfile(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
    );
    await _local.cacheProfile(result);
    return result;
  }

  /// ✅ Update profile with photo — works on web + native
  Future<ProfileModel> updateProfileWithPhoto({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? photoFilePath,        // Native
    Uint8List? photoBytes,        // ✅ Web
    String? photoFileName,        // ✅ Web
  }) async {
    final result = await _remote.updateProfileWithPhoto(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      photoFilePath: photoFilePath,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
    );
    await _local.cacheProfile(result);
    return result;
  }

  Future<ProfileModel> updatePatientProfile({
    required PatientProfileModel patientProfile,
  }) async {
    final result = await _remote.updatePatientProfile(
      patientProfileId: patientProfile.id,
      patientProfile: patientProfile,
    );
    await _local.cacheProfile(result);
    return result;
  }

  Future<void> clearCache() => _local.clearCache();
}