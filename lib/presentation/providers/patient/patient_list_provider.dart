// lib/presentation/providers/patient/patient_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/repositories/patient_repository.dart';

// ─── List State ───────────────────────────────────────────────
class PatientListState {
  final List<PatientModel> patients;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  // ✅ Pagination fields
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  const PatientListState({
    this.patients = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 10,
    this.total = 0,
    this.hasMore = false,
  });

  PatientListState copyWith({
    List<PatientModel>? patients,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
    bool? hasMore,
  }) {
    return PatientListState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ─── Paginated Result Wrapper ─────────────────────────────────
class PatientPaginatedResult {
  final List<PatientModel> patients;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  const PatientPaginatedResult({
    required this.patients,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });
}

// ─── List Provider ────────────────────────────────────────────
final patientListProvider =
    StateNotifierProvider<PatientListNotifier, PatientListState>((ref) {
  return PatientListNotifier(ref.watch(patientRepositoryProvider));
});

class PatientListNotifier extends StateNotifier<PatientListState> {
  final PatientRepository _repository;

  PatientListNotifier(this._repository) : super(const PatientListState()) {
    load();
  }

  Future<void> load({
    int page = 1,
    String? search,
    int? perPage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.getAllPaginated(
        page: page,
        perPage: perPage ?? state.perPage,
        search: search,
      );

      state = state.copyWith(
        patients: result.patients,
        isLoading: false,
        searchQuery: search ?? '',
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        perPage: result.perPage,
        total: result.total,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() =>
      load(page: state.currentPage, search: state.searchQuery);

  Future<void> search(String query) => load(page: 1, search: query);

  Future<void> goToPage(int page) {
    if (page < 1 || page > state.lastPage) return Future.value();
    return load(page: page, search: state.searchQuery);
  }

  Future<void> nextPage() {
    if (!state.hasMore) return Future.value();
    return goToPage(state.currentPage + 1);
  }

  Future<void> previousPage() {
    if (state.currentPage <= 1) return Future.value();
    return goToPage(state.currentPage - 1);
  }

  Future<void> changePerPage(int perPage) {
    return load(page: 1, perPage: perPage, search: state.searchQuery);
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      // Reload current page after delete
      await refresh();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

// ─── Detail Provider ──────────────────────────────────────────
final patientDetailProvider =
    FutureProvider.autoDispose.family<PatientModel, int>((ref, id) async {
  final repo = ref.watch(patientRepositoryProvider);
  return repo.getById(id);
});