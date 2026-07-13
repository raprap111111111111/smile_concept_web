// lib/presentation/providers/treatment/treatment_plan_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/treatment_plan_remote_datasource.dart';
import '../../../data/models/treatment/treatment_plan_model.dart';
import '../../../data/repositories/treatment_plan_repository.dart';

final treatmentPlanRemoteDataSourceProvider =
    Provider<TreatmentPlanRemoteDataSource>((ref) {
  return TreatmentPlanRemoteDataSource(
      dio: ref.read(dioProvider));
});

final treatmentPlanRepositoryProvider =
    Provider<TreatmentPlanRepository>((ref) {
  return TreatmentPlanRepository(
    remoteDataSource:
        ref.read(treatmentPlanRemoteDataSourceProvider),
  );
});

// ── State ──────────────────────────────────────────────────────
class TreatmentPlanState {
  final List<TreatmentPlanModel> plans;
  final TreatmentPlanModel? selected;
  final bool isListLoading;
  final bool isDetailLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? listError;
  final String? detailError;
  final int currentPage;
  final int lastPage;

  const TreatmentPlanState({
    this.plans           = const [],
    this.selected,
    this.isListLoading   = false,
    this.isDetailLoading = false,
    this.isLoadingMore   = false,
    this.isSubmitting    = false,
    this.listError,
    this.detailError,
    this.currentPage     = 1,
    this.lastPage        = 1,
  });

  bool get hasListError   => listError != null;
  bool get hasDetailError => detailError != null;
  bool get hasMore        => currentPage < lastPage;
  bool get isEmpty =>
      !isListLoading && plans.isEmpty && listError == null;

  TreatmentPlanState copyWith({
    List<TreatmentPlanModel>? plans,
    TreatmentPlanModel? selected,
    bool? isListLoading,
    bool? isDetailLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? listError,
    String? detailError,
    int? currentPage,
    int? lastPage,
    bool clearSelected    = false,
    bool clearListError   = false,
    bool clearDetailError = false,
  }) {
    return TreatmentPlanState(
      plans:           plans           ?? this.plans,
      selected:        clearSelected   ? null : selected ?? this.selected,
      isListLoading:   isListLoading   ?? this.isListLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isLoadingMore:   isLoadingMore   ?? this.isLoadingMore,
      isSubmitting:    isSubmitting    ?? this.isSubmitting,
      listError:  clearListError  ? null : listError  ?? this.listError,
      detailError: clearDetailError ? null : detailError ?? this.detailError,
      currentPage: currentPage ?? this.currentPage,
      lastPage:    lastPage    ?? this.lastPage,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────
class TreatmentPlanNotifier
    extends StateNotifier<TreatmentPlanState> {
  final TreatmentPlanRepository _repository;

  int? _filterPatientId;
  int? _filterDoctorId;
  String? _filterStatus;

  TreatmentPlanNotifier(this._repository)
      : super(const TreatmentPlanState());

  Future<void> loadPlans({
    int? patientId,
    int? doctorId,
    String? status,
    bool forceRefresh = false,
  }) async {
    _filterPatientId = patientId;
    _filterDoctorId  = doctorId;
    _filterStatus    = status;

    state = state.copyWith(
      isListLoading:  true,
      clearListError: true,
      currentPage:    1,
    );

    try {
      final result = await _repository.getTreatmentPlans(
        page:      1,
        patientId: patientId,
        doctorId:  doctorId,
        status:    status,
      );

      state = state.copyWith(
        plans:         result.plans,
        currentPage:   result.currentPage,
        lastPage:      result.lastPage,
        isListLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isListLoading: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getTreatmentPlans(
        page:      state.currentPage + 1,
        patientId: _filterPatientId,
        doctorId:  _filterDoctorId,
        status:    _filterStatus,
      );

      state = state.copyWith(
        plans:        [...state.plans, ...result.plans],
        currentPage:  result.currentPage,
        lastPage:     result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        listError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadById(int id,
      {bool forceRefresh = false}) async {
    state = state.copyWith(
      isDetailLoading:  true,
      clearDetailError: true,
      clearSelected:    true,
    );

    try {
      final result =
          await _repository.getTreatmentPlanById(id);
      state = state.copyWith(
        selected:        result,
        isDetailLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isDetailLoading: false,
        detailError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> deletePlan(int id) async {
    try {
      await _repository.remoteDataSource
          .deleteTreatmentPlan(id);
      state = state.copyWith(
        plans: state.plans.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        listError: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> refresh() => loadPlans(
        patientId:    _filterPatientId,
        doctorId:     _filterDoctorId,
        status:       _filterStatus,
        forceRefresh: true,
      );
}

final treatmentPlanProvider = StateNotifierProvider<
    TreatmentPlanNotifier,
    TreatmentPlanState>((ref) {
  return TreatmentPlanNotifier(
      ref.read(treatmentPlanRepositoryProvider));
});