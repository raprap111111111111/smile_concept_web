// lib/presentation/providers/clinical_records/clinical_records_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/clinical_records_remote_datasource.dart';
import '../../../data/models/clinical_records/clinical_summary_model.dart';
import '../../../data/repositories/clinical_records_repository.dart';

// ── Data source provider ───────────────────────────────────────
final clinicalRecordsRemoteDataSourceProvider =
    Provider<ClinicalRecordsRemoteDataSource>((ref) {
  return ClinicalRecordsRemoteDataSource(dio: ref.read(dioProvider));
});

// ── Repository provider ────────────────────────────────────────
final clinicalRecordsRepositoryProvider =
    Provider<ClinicalRecordsRepository>((ref) {
  return ClinicalRecordsRepository(
    remoteDataSource: ref.read(clinicalRecordsRemoteDataSourceProvider),
  );
});

// ── State ──────────────────────────────────────────────────────
class ClinicalRecordsState {
  final ClinicalSummaryModel? summary;
  final bool isLoading;
  final String? error;

  const ClinicalRecordsState({
    this.summary,
    this.isLoading = false,
    this.error,
  });

  bool get hasError => error != null;
  bool get isEmpty =>
      !isLoading &&
      summary == null &&
      error == null;

  ClinicalRecordsState copyWith({
    ClinicalSummaryModel? summary,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClinicalRecordsState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────
class ClinicalRecordsNotifier extends StateNotifier<ClinicalRecordsState> {
  final ClinicalRecordsRepository _repository;

  ClinicalRecordsNotifier(this._repository)
      : super(const ClinicalRecordsState());

  Future<void> loadSummary({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final summary =
          await _repository.getSummary(forceRefresh: forceRefresh);

      state = state.copyWith(
        summary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => loadSummary(forceRefresh: true);
}

// ── Final provider ─────────────────────────────────────────────
final clinicalRecordsProvider = StateNotifierProvider<
    ClinicalRecordsNotifier, ClinicalRecordsState>((ref) {
  return ClinicalRecordsNotifier(
    ref.read(clinicalRecordsRepositoryProvider),
  );
});