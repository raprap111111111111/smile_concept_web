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

  TreatmentRepository({required this.remoteDataSource});

  // ── Get paginated list ─────────────────────────────────────
  Future<TreatmentResult> getTreatments({
    int page = 1,
    bool? isActive,
    String? search,
    bool forceRefresh = false,
  }) async {
    final raw = await remoteDataSource.fetchTreatments(
      page: page,
      isActive: isActive,
      search: search,
    );

    // ✅ FIXED: Match your actual API structure
    // Your API returns:
    // {
    //   "success": true,
    //   "data": {
    //     "records": [...],    ← items here
    //     "total": 11,
    //     "current_page": 1,   ← pagination flat inside data
    //     "last_page": 1,
    //     "has_more": false
    //   }
    // }
    final data = raw['data'] as Map<String, dynamic>;
    final items = data['records'] as List<dynamic>? ?? [];

    final treatments = items
        .map((e) => TreatmentModel.fromJson(
              _toMap(e as Map),
            ))
        .toList();

    if (page == 1) _cachedTreatments = treatments;

    return TreatmentResult(
      treatments: treatments,
      currentPage: (data['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (data['last_page'] as num?)?.toInt() ?? 1,
      total: (data['total'] as num?)?.toInt() ?? 0,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  // ── Get single ─────────────────────────────────────────────
  Future<TreatmentModel> getTreatmentById(int id) async {
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
    clearCache();
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
    clearCache();
    return result;
  }

  // ── Clear cache ────────────────────────────────────────────
  void clearCache() => _cachedTreatments = null;

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}