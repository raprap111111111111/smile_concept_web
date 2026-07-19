import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/models/patient_attachment/patient_with_attachments.dart';
import 'patient_attachment_provider.dart';

// ═══════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════
class PatientsWithAttachmentsState {
  final List<PatientWithAttachments> patients;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int currentPage;
  final int lastPage;

  const PatientsWithAttachmentsState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;

  PatientsWithAttachmentsState copyWith({
    List<PatientWithAttachments>? patients,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? currentPage,
    int? lastPage,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return PatientsWithAttachmentsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════
class PatientsWithAttachmentsNotifier
    extends StateNotifier<PatientsWithAttachmentsState> {
  final Ref _ref;

  PatientsWithAttachmentsNotifier(this._ref)
      : super(const PatientsWithAttachmentsState()) {
    fetch();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(currentPage: 1, clearError: true);
    }

    state = state.copyWith(isLoading: true);

    try {
      final service = _ref.read(patientAttachmentServiceProvider);
      final result = await service.getPatientsWithAttachments(
        page: state.currentPage,
        search: state.searchQuery,
      );

      final data = result['data'] as Map<String, dynamic>;
      final records = (data['records'] as List?) ?? [];

      final incoming = records
          .map((e) =>
              PatientWithAttachments.fromJson(e as Map<String, dynamic>))
          .toList();

      final merged =
          refresh ? incoming : [...state.patients, ...incoming];

      state = state.copyWith(
        patients: merged,
        lastPage: data['last_page'] as int? ?? 1,
        isLoading: false,
        clearError: true,
      );
    } catch (e, stack) {
      debugPrint('❌ fetch patients error: $e');
      debugPrint('📍 $stack');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetch();
  }

  Future<void> setSearch(String? query) async {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
    await fetch(refresh: true);
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════
final patientsWithAttachmentsProvider = StateNotifierProvider<
    PatientsWithAttachmentsNotifier,
    PatientsWithAttachmentsState>((ref) {
  return PatientsWithAttachmentsNotifier(ref);
});