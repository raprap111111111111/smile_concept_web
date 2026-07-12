// lib/presentation/providers/prescription/prescription_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/prescription/prescription_model.dart';
import '../../../data/repositories/prescription_repository.dart';
import '../../../data/datasources/remote/prescription_remote_datasource.dart';
import '../../../core/network/dio_client.dart';

final prescriptionRemoteDataSourceProvider =
    Provider<PrescriptionRemoteDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return PrescriptionRemoteDataSource(dio: dio);
});

final prescriptionRepositoryProvider =
    Provider<PrescriptionRepository>((ref) {
  final remote = ref.read(prescriptionRemoteDataSourceProvider);
  return PrescriptionRepository(remoteDataSource: remote);
});

// ─── State ────────────────────────────────────────────────────
class PrescriptionState {
  final List<PrescriptionModel> prescriptions;
  final PrescriptionModel? selected;
  final bool isListLoading;
  final bool isDetailLoading;
  final bool isLoadingMore;
  final String? listError;
  final String? detailError;
  final int currentPage;
  final int lastPage;

  const PrescriptionState({
    this.prescriptions = const [],
    this.selected,
    this.isListLoading = false,
    this.isDetailLoading = false,
    this.isLoadingMore = false,
    this.listError,
    this.detailError,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasListError => listError != null;
  bool get hasDetailError => detailError != null;
  bool get hasMore => currentPage < lastPage;
  bool get isEmpty =>
      !isListLoading && prescriptions.isEmpty && listError == null;

  PrescriptionState copyWith({
    List<PrescriptionModel>? prescriptions,
    PrescriptionModel? selected,
    bool? isListLoading,
    bool? isDetailLoading,
    bool? isLoadingMore,
    String? listError,
    String? detailError,
    int? currentPage,
    int? lastPage,
    bool clearSelected = false,
    bool clearListError = false,
    bool clearDetailError = false,
  }) {
    return PrescriptionState(
      prescriptions: prescriptions ?? this.prescriptions,
      selected: clearSelected ? null : selected ?? this.selected,
      isListLoading: isListLoading ?? this.isListLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      listError: clearListError ? null : listError ?? this.listError,
      detailError: clearDetailError ? null : detailError ?? this.detailError,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────
class PrescriptionNotifier extends StateNotifier<PrescriptionState> {
  final PrescriptionRepository _repository;

  int? _filterPatientId;
  int? _filterDoctorId;

  PrescriptionNotifier(this._repository) : super(const PrescriptionState());

  Future<void> loadPrescriptions({
    int? patientId,
    int? doctorId,
    bool forceRefresh = false,
  }) async {
    _filterPatientId = patientId;
    _filterDoctorId = doctorId;

    state = state.copyWith(
      isListLoading: true,
      clearListError: true,
      currentPage: 1,
    );

    try {
      final result = await _repository.getPrescriptions(
        page: 1,
        patientId: patientId,
        doctorId: doctorId,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        prescriptions: result.prescriptions,
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

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getPrescriptions(
        page: state.currentPage + 1,
        patientId: _filterPatientId,
        doctorId: _filterDoctorId,
      );

      state = state.copyWith(
        prescriptions: [...state.prescriptions, ...result.prescriptions],
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

  Future<void> loadById(int id, {bool forceRefresh = false}) async {
    state = state.copyWith(
      isDetailLoading: true,
      clearDetailError: true,
      clearSelected: true,
    );

    try {
      final result = await _repository.getPrescriptionById(
        id,
        forceRefresh: forceRefresh,
      );

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

  // ─── DELETE PRESCRIPTION ────────────────────────────────────
  Future<bool> deletePrescription(int id) async {
    try {
      await _repository.remoteDataSource.deletePrescription(id);

      // Optimistic update - remove from list immediately
      state = state.copyWith(
        prescriptions:
            state.prescriptions.where((p) => p.id != id).toList(),
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

  Future<void> refresh() => loadPrescriptions(
        patientId: _filterPatientId,
        doctorId: _filterDoctorId,
        forceRefresh: true,
      );

  void reset() {
    state = const PrescriptionState();
  }
}

// ─── Final Provider ───────────────────────────────────────────
final prescriptionProvider =
    StateNotifierProvider<PrescriptionNotifier, PrescriptionState>((ref) {
  final repository = ref.read(prescriptionRepositoryProvider);
  return PrescriptionNotifier(repository);
});