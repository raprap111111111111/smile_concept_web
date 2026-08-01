// lib/presentation/providers/lab_case/lab_case_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smile_concept_web/data/models/lab_case/lab_case_model.dart';
import 'package:smile_concept_web/data/repositories/lab_case_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LabCaseState {
  final List<LabCaseModel> items;
  final int total;
  final int page;
  final int limit;
  final String? search;
  final String? statusFilter;
  final int? appointmentIdFilter;
  final String orderBy;
  final String orderDir;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const LabCaseState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 15,
    this.search,
    this.statusFilter,
    this.appointmentIdFilter,
    this.orderBy = 'due_date',
    this.orderDir = 'asc',
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  int get offset => (page - 1) * limit;
  int get totalPages => (total / limit).ceil().clamp(1, 9999);
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;

  LabCaseState copyWith({
    List<LabCaseModel>? items,
    int? total,
    int? page,
    int? limit,
    String? search,
    String? statusFilter,
    int? appointmentIdFilter,
    String? orderBy,
    String? orderDir,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearSearch = false,
    bool clearStatusFilter = false,
    bool clearAppointmentFilter = false,
    bool clearError = false,
  }) {
    return LabCaseState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : search ?? this.search,
      statusFilter:
          clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      appointmentIdFilter: clearAppointmentFilter
          ? null
          : appointmentIdFilter ?? this.appointmentIdFilter,
      orderBy: orderBy ?? this.orderBy,
      orderDir: orderDir ?? this.orderDir,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LabCaseNotifier extends StateNotifier<LabCaseState> {
  final LabCaseRepository _repository;

  LabCaseNotifier(this._repository) : super(const LabCaseState());

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchLabCases() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{
        'offset': state.offset,
        'limit': state.limit,
        'order_by': state.orderBy,
        'order_dir': state.orderDir,
        if (state.search != null && state.search!.isNotEmpty)
          'search': state.search,
        if (state.statusFilter != null) 'status': state.statusFilter,
        if (state.appointmentIdFilter != null)
          'appointment_id': state.appointmentIdFilter,
      };

      final response = await _repository.getAll(params: params);
      state = state.copyWith(
        items: response.items,
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  Future<void> setPage(int page) async {
    if (page < 1 || page > state.totalPages) return;
    state = state.copyWith(page: page);
    await fetchLabCases();
  }

  Future<void> setLimit(int limit) async {
    state = state.copyWith(limit: limit, page: 1);
    await fetchLabCases();
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  Future<void> setSearch(String? value) async {
    state = state.copyWith(
      search: value,
      page: 1,
      clearSearch: value == null || value.isEmpty,
    );
    await fetchLabCases();
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      page: 1,
      clearStatusFilter: status == null,
    );
    await fetchLabCases();
  }

  Future<void> setAppointmentFilter(int? appointmentId) async {
    state = state.copyWith(
      appointmentIdFilter: appointmentId,
      page: 1,
      clearAppointmentFilter: appointmentId == null,
    );
    await fetchLabCases();
  }

  Future<void> setOrdering(String orderBy, String orderDir) async {
    state = state.copyWith(orderBy: orderBy, orderDir: orderDir, page: 1);
    await fetchLabCases();
  }

  Future<void> resetFilters() async {
    state = const LabCaseState();
    await fetchLabCases();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<bool> createLabCase(Map<String, dynamic> body) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final created = await _repository.create(body);
      state = state.copyWith(isSubmitting: false);
      // Optimistically prepend then re-fetch for correct ordering
      await fetchLabCases();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateLabCase(int id, Map<String, dynamic> body) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _repository.update(id, body);
      // Replace in-place
      final updatedItems = state.items
          .map((item) => item.id == id ? updated : item)
          .toList();
      state = state.copyWith(items: updatedItems, isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteLabCase(int id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.delete(id);
      final updatedItems =
          state.items.where((item) => item.id != id).toList();
      state = state.copyWith(
        items: updatedItems,
        total: state.total - 1,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─── Providers ────────────────────────────────────────────────────────────────

final labCaseProvider =
    StateNotifierProvider<LabCaseNotifier, LabCaseState>((ref) {
  final repository = ref.watch(labCaseRepositoryProvider);
  return LabCaseNotifier(repository);
});

// Single item provider (for edit / detail pages)
final labCaseSingleProvider =
    FutureProvider.family<LabCaseModel, int>((ref, id) async {
  final repository = ref.watch(labCaseRepositoryProvider);
  return repository.getOne(id);
});