import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/consent/patient_consent_model.dart';

final consentLocalDataSourceProvider =
    Provider<ConsentLocalDataSource>((ref) {
  return ConsentLocalDataSource();
});

/// Placeholder local cache. Wire up your existing storage
/// (Hive / SharedPreferences / SQLite) if needed.
class ConsentLocalDataSource {
  final Map<int, PatientConsentModel> _cache = {};

  Future<void> cacheConsent(PatientConsentModel consent) async {
    _cache[consent.id] = consent;
  }

  Future<PatientConsentModel?> getCachedConsent(int id) async {
    return _cache[id];
  }

  Future<void> clearCache() async {
    _cache.clear();
  }
}