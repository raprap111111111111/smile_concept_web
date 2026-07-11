// lib/data/datasources/local/profile_local_datasource.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profile/profile_model.dart';

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

class ProfileLocalDataSource {
  // ─── In-memory cache ─────────────────────────────────────────────
  ProfileModel? _cachedProfile;
  DateTime? _cachedAt;

  static const Duration _cacheDuration = Duration(minutes: 15);

  // ─── Get cached (returns null if expired) ────────────────────────
  Future<ProfileModel?> getCachedProfile() async {
    if (_cachedProfile == null || _cachedAt == null) return null;

    final age = DateTime.now().difference(_cachedAt!);
    if (age > _cacheDuration) {
      await clearCache();
      return null;
    }

    return _cachedProfile;
  }

  // ─── Save to cache ───────────────────────────────────────────────
  Future<void> cacheProfile(ProfileModel profile) async {
    _cachedProfile = profile;
    _cachedAt = DateTime.now();
  }

  // ─── Clear cache ─────────────────────────────────────────────────
  Future<void> clearCache() async {
    _cachedProfile = null;
    _cachedAt = null;
  }
}