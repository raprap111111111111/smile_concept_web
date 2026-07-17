// lib/data/repositories/clinical_records_repository.dart

import '../datasources/remote/clinical_records_remote_datasource.dart';
import '../models/clinical_records/clinical_summary_model.dart';

class ClinicalRecordsRepository {
  final ClinicalRecordsRemoteDataSource remoteDataSource;

  ClinicalSummaryModel? _cachedSummary;
  DateTime? _lastFetch;

  ClinicalRecordsRepository({required this.remoteDataSource});

  Future<ClinicalSummaryModel> getSummary({
    bool forceRefresh = false,
  }) async {
    // Cache for 2 minutes
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedSummary != null &&
        _lastFetch != null &&
        now.difference(_lastFetch!).inMinutes < 2) {
      return _cachedSummary!;
    }

    final summary = await remoteDataSource.fetchSummary();
    _cachedSummary = summary;
    _lastFetch = now;
    return summary;
  }

  void clearCache() {
    _cachedSummary = null;
    _lastFetch = null;
  }
}