// lib/data/repositories/prescription_repository.dart

import '../datasources/remote/prescription_remote_datasource.dart';
import '../models/prescription/prescription_model.dart';

class PrescriptionPaginatedResult {
  final List<PrescriptionModel> prescriptions;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  const PrescriptionPaginatedResult({
    required this.prescriptions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });
}

class _CacheEntry<T> {
  final T data;
  final DateTime cachedAt;

  const _CacheEntry({
    required this.data,
    required this.cachedAt,
  });
}

class PrescriptionRepository {
  final PrescriptionRemoteDataSource remoteDataSource;

  PrescriptionRepository({required this.remoteDataSource});

  final Map<String, _CacheEntry<dynamic>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  String _listKey(int page, int? patientId, int? doctorId) =>
      'prescriptions_page_${page}_patient_${patientId}_doctor_${doctorId}';

  String _detailKey(int id) => 'prescription_$id';

  bool _isCacheValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.cachedAt) < _cacheDuration;
  }

  Future<PrescriptionPaginatedResult> getPrescriptions({
    int page = 1,
    int? patientId,
    int? doctorId,
    bool forceRefresh = false,
  }) async {
    final key = _listKey(page, patientId, doctorId);

    if (!forceRefresh && _isCacheValid(key)) {
      return _cache[key]!.data as PrescriptionPaginatedResult;
    }

    final raw = await remoteDataSource.fetchPrescriptions(
      page: page,
      patientId: patientId,
      doctorId: doctorId,
    );

    final data = raw['data'] as Map<String, dynamic>;

    // ✅ FIXED: Backend returns 'records' (not 'data')
    final rawList = (data['records'] as List<dynamic>?) ?? [];

    final result = PrescriptionPaginatedResult(
      prescriptions: rawList
          .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (data['current_page'] as int?) ?? 1,
      lastPage: (data['last_page'] as int?) ?? 1,
      total: (data['total'] as int?) ?? 0,
      hasMore: (data['has_more'] as bool?) ?? false,
    );

    _cache[key] = _CacheEntry(
      data: result,
      cachedAt: DateTime.now(),
    );

    return result;
  }

  Future<PrescriptionModel> getPrescriptionById(
    int id, {
    bool forceRefresh = false,
  }) async {
    final key = _detailKey(id);

    if (!forceRefresh && _isCacheValid(key)) {
      return _cache[key]!.data as PrescriptionModel;
    }

    final result = await remoteDataSource.fetchPrescriptionById(id);

    _cache[key] = _CacheEntry(
      data: result,
      cachedAt: DateTime.now(),
    );

    return result;
  }

  void clearCache() {
    _cache.clear();
  }
}