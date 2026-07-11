// lib/presentation/providers/profile/profile_provider.dart

import 'dart:typed_data'; // ✅ ADD THIS
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile/patient_profile_model.dart';
import '../../../data/models/profile/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasProfile => profile != null;
  bool get needsMedicalSetup =>
      profile?.isPatient == true && profile?.needsSetup == true;
  bool get isEmailVerified => profile?.isEmailVerified ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState());

  Future<void> loadProfile({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _repository.getMyProfile(
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return false;

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updated = await _repository.updateProfile(
        userId: currentProfile.id,
        name: name,
        email: email,
        phone: phone,
      );
      state = state.copyWith(isUpdating: false, profile: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  /// ✅ Update profile WITH photo (web + native)
  Future<bool> updateProfileWithPhoto({
    String? name,
    String? email,
    String? phone,
    String? photoFilePath,      // Native
    Uint8List? photoBytes,      // ✅ Web
    String? photoFileName,      // ✅ Web
  }) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return false;

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updated = await _repository.updateProfileWithPhoto(
        userId: currentProfile.id,
        name: name,
        email: email,
        phone: phone,
        photoFilePath: photoFilePath,
        photoBytes: photoBytes,
        photoFileName: photoFileName,
      );
      state = state.copyWith(isUpdating: false, profile: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updatePatientProfile(PatientProfileModel updated) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final profile = await _repository.updatePatientProfile(
        patientProfile: updated,
      );
      state = state.copyWith(isUpdating: false, profile: profile);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

final currentProfileProvider = Provider<ProfileModel?>((ref) {
  return ref.watch(profileNotifierProvider).profile;
});