// lib/data/repositories/treatment_repository.dart

import '../datasources/remote/treatment_remote_datasource.dart';
import '../models/treatment/treatment_model.dart';

class TreatmentResult {
  final List<TreatmentModel> treatments;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  const TreatmentResult({
    required this.treatments,
    required this.currentPage,
    required this.lastPage,
    this.total = 0,
    this.hasMore = false,
  });
}

class TreatmentRepository {
  final TreatmentRemoteDataSource remoteDataSource;

  // ── Simple in-memory cache ─────────────────────────────────
  List<TreatmentModel>? _cachedTreatments;
  TreatmentResult? _cachedResult;

  TreatmentRepository({required this.remoteDataSource});

  // ── Get paginated list ─────────────────────────────────────
  Future<TreatmentResult> getTreatments({
    int page = 1,
    bool? isActive,
    String? search,
    bool forceRefresh = false,
  }) async {
    // 1. Return cache if available and conditions are met
    if (
      !forceRefresh &&
      page == 1 &&
      search == null &&
      isActive == null &&
      _cachedTreatments != null &&
      _cachedResult != null
    ) {
      return _cachedResult!;
    }

    // 2. Fetch from API
    final raw = await remoteDataSource.fetchTreatments(
      page: page,
      isActive: isActive,
      search: search,
    );

    final data = raw['data'] as Map<String, dynamic>;
    final items = data['records'] as List<dynamic>? ?? [];

    final treatments = items
        .map((e) => TreatmentModel.fromJson(
              _toMap(e as Map),
            ))
        .toList();

    final result = TreatmentResult(
      treatments: treatments,
      currentPage: (data['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (data['last_page'] as num?)?.toInt() ?? 1,
      total: (data['total'] as num?)?.toInt() ?? 0,
      hasMore: data['has_more'] as bool? ?? false,
    );

    // 3. Only cache page 1 with no filters applied
    if (page == 1 && search == null && isActive == null) {
      _cachedTreatments = treatments; // READ + WRITE — fixes unused_field warning
      _cachedResult = result;
    }

    return result;
  }

  // ── Get single ─────────────────────────────────────────────
  Future<TreatmentModel> getTreatmentById(int id) async {
    // 1. Try to find in cache first to avoid extra API call
    final cached = _cachedTreatments?.where((t) => t.id == id).firstOrNull;
    if (cached != null) return cached;

    // 2. Fallback to API if not in cache
    return remoteDataSource.fetchTreatmentById(id);
  }

  // ── Create ─────────────────────────────────────────────────
  Future<TreatmentModel> createTreatment({
    required String name,
    required double price,
    String? description,
    int estimatedDurationMinutes = 30,
    bool isActive = true,
  }) async {
    final result = await remoteDataSource.createTreatment(
      name: name,
      price: price,
      description: description,
      estimatedDurationMinutes: estimatedDurationMinutes,
      isActive: isActive,
    );
    clearCache(); // Invalidate cache after create
    return result;
  }

  // ── Update ─────────────────────────────────────────────────
  Future<TreatmentModel> updateTreatment({
    required int id,
    String? name,
    double? price,
    String? description,
    int? estimatedDurationMinutes,
    bool? isActive,
  }) async {
    final result = await remoteDataSource.updateTreatment(
      id: id,
      name: name,
      price: price,
      description: description,
      estimatedDurationMinutes: estimatedDurationMinutes,
      isActive: isActive,
    );
    clearCache(); // Invalidate cache after update
    return result;
  }

  // ── Clear cache ────────────────────────────────────────────
  void clearCache() {
    _cachedTreatments = null;
    _cachedResult = null;
  }

  // ── Private helper ─────────────────────────────────────────
  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}