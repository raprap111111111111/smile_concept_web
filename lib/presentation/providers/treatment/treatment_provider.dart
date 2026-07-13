// lib/presentation/providers/treatment/treatment_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/treatment_remote_datasource.dart';
import '../../../data/models/treatment/treatment_model.dart';
import '../../../data/repositories/treatment_repository.dart';

// ── Data source provider ───────────────────────────────────────
final treatmentRemoteDataSourceProvider =
    Provider<TreatmentRemoteDataSource>((ref) {
  return TreatmentRemoteDataSource(dio: ref.read(dioProvider));
});

// ── Repository provider ────────────────────────────────────────
final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  return TreatmentRepository(
    remoteDataSource: ref.read(treatmentRemoteDataSourceProvider),
  );
});

// ── State ──────────────────────────────────────────────────────
class TreatmentState {
  final List<TreatmentModel> treatments;
  final TreatmentModel? selected;
  final bool isListLoading;
  final bool isDetailLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? listError;
  final String? detailError;
  final String? submitError;
  final int currentPage;
  final int lastPage;

  const TreatmentState({
    this.treatments = const [],
    this.selected,
    this.isListLoading = false,
    this.isDetailLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.listError,
    this.detailError,
    this.submitError,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasListError => listError != null;
  bool get hasDetailError => detailError != null;
  bool get hasSubmitError => submitError != null;
  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => !isListLoading && treatments.isEmpty && listError == null;

  TreatmentState copyWith({
    List<TreatmentModel>? treatments,
    TreatmentModel? selected,
    bool? isListLoading,
    bool? isDetailLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? listError,
    String? detailError,
    String? submitError,
    int? currentPage,
    int? lastPage,
    bool clearSelected = false,
    bool clearListError = false,
    bool clearDetailError = false,
    bool clearSubmitError = false,
  }) {
    return TreatmentState(
      treatments: treatments ?? this.treatments,
      selected: clearSelected ? null : selected ?? this.selected,
      isListLoading: isListLoading ?? this.isListLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      listError: clearListError ? null : listError ?? this.listError,
      detailError: clearDetailError ? null : detailError ?? this.detailError,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────
class TreatmentNotifier extends StateNotifier<TreatmentState> {
  final TreatmentRepository _repository;

  TreatmentNotifier(this._repository) : super(const TreatmentState());

  // ── Load list ──────────────────────────────────────────────
  Future<void> loadTreatments({
    bool? isActive,
    String? search,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(
      isListLoading: true,
      clearListError: true,
      currentPage: 1,
    );

    try {
      final result = await _repository.getTreatments(
        page: 1,
        isActive: isActive,
        search: search,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        treatments: result.treatments,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        isListLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isListLoading: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Load more ──────────────────────────────────────────────
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getTreatments(
        page: state.currentPage + 1,
      );

      state = state.copyWith(
        treatments: [...state.treatments, ...result.treatments],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Load single ────────────────────────────────────────────
  Future<void> loadById(int id) async {
    state = state.copyWith(
      isDetailLoading: true,
      clearDetailError: true,
      clearSelected: true,
    );

    try {
      final result = await _repository.getTreatmentById(id);
      state = state.copyWith(
        selected: result,
        isDetailLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isDetailLoading: false,
        detailError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Create ─────────────────────────────────────────────────
  // lib/presentation/providers/treatment/treatment_provider.dart
// Only the createTreatment and updateTreatment methods need updating
// Replace the two methods in TreatmentNotifier with these:

  // ── Create ─────────────────────────────────────────────────
  Future<void> createTreatment({
    required String name,
    required double price,
    String? description,
    int estimatedDurationMinutes = 30,
    bool isActive = true,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      await _repository.createTreatment(
        name: name,
        price: price,
        description: description,
        estimatedDurationMinutes: estimatedDurationMinutes,
        isActive: isActive,
      );

      state = state.copyWith(isSubmitting: false);
      await loadTreatments(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ── Update ─────────────────────────────────────────────────
  Future<void> updateTreatment({
    required int id,
    String? name,
    double? price,
    String? description,
    int? estimatedDurationMinutes,
    bool? isActive,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      final updated = await _repository.updateTreatment(
        id: id,
        name: name,
        price: price,
        description: description,
        estimatedDurationMinutes: estimatedDurationMinutes,
        isActive: isActive,
      );

      // Replace updated item in list immediately
      final updatedList = state.treatments.map((t) {
        return t.id == id ? updated : t;
      }).toList();

      state = state.copyWith(
        isSubmitting: false,
        treatments: updatedList,
        selected: updated,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ── Delete ─────────────────────────────────────────────────
  Future<bool> deleteTreatment(int id) async {
    try {
      await _repository.remoteDataSource.deleteTreatment(id);
      state = state.copyWith(
        treatments: state.treatments.where((t) => t.id != id).toList(),
      );
      _repository.clearCache();
      return true;
    } catch (e) {
      state = state.copyWith(
        listError: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> refresh() => loadTreatments(forceRefresh: true);
}

// ── Final provider ─────────────────────────────────────────────
final treatmentProvider =
    StateNotifierProvider<TreatmentNotifier, TreatmentState>((ref) {
  return TreatmentNotifier(ref.read(treatmentRepositoryProvider));
});

// ── Simple list for dropdowns ──────────────────────────────────
final treatmentSimpleListProvider =
    FutureProvider<List<TreatmentModel>>((ref) async {
  final repo = ref.read(treatmentRepositoryProvider);
  final result = await repo.getTreatments(isActive: true);
  return result.treatments;
});
