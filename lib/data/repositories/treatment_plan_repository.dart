// lib/data/repositories/treatment_plan_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../datasources/remote/treatment_plan_remote_datasource.dart';
import '../models/treatment/treatment_plan_model.dart';

class TreatmentPlanResult {
  final List<TreatmentPlanModel> plans;
  final int currentPage;
  final int lastPage;

  const TreatmentPlanResult({
    required this.plans,
    required this.currentPage,
    required this.lastPage,
  });
}

class TreatmentPlanRepository {
  final TreatmentPlanRemoteDataSource remoteDataSource;

  TreatmentPlanRepository({required this.remoteDataSource});

  // ── GET list ───────────────────────────────────────────────
  Future<TreatmentPlanResult> getTreatmentPlans({
    int page = 1,
    int? patientId,
    int? doctorId,
    String? status,
    bool forceRefresh = false,
  }) async {
    final raw = await remoteDataSource.fetchTreatmentPlans(
      page: page,
      patientId: patientId,
      doctorId: doctorId,
      status: status,
    );

    final outer = raw['data'];

    List<dynamic> items;
    Map pagination = {};

    if (outer is List) {
      items = outer;
    } else if (outer is Map) {
      final list = outer['records'] ?? outer['data'] ?? outer['items'];
      items = (list is List) ? list : [];
      pagination = (outer['meta'] is Map)
          ? outer['meta'] as Map
          : (outer['pagination'] is Map)
              ? outer['pagination'] as Map
              : outer;
    } else {
      items = [];
    }

    final plans = items
        .whereType<Map>()
        .map((e) => TreatmentPlanModel.fromJson(_toMap(e)))
        .toList();

    return TreatmentPlanResult(
      plans: plans,
      currentPage: (pagination['current_page'] as num?)?.toInt() ?? page,
      lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  // ── GET single ─────────────────────────────────────────────
  Future<TreatmentPlanModel> getTreatmentPlanById(int id) =>
      remoteDataSource.fetchTreatmentPlanById(id);

  // ── CREATE ─────────────────────────────────────────────────
  Future<TreatmentPlanModel> create({
    required int userId,
    required int doctorId,
    required String name,
    required List<Map<String, dynamic>> items,
    String status = 'proposed',
    String? notes,
  }) {
    return remoteDataSource.createTreatmentPlan(
      userId: userId,
      doctorId: doctorId,
      name: name,
      items: items,
      status: status,
      notes: notes,
    );
  }

  // ── UPDATE ─────────────────────────────────────────────────
  Future<TreatmentPlanModel> update({
    required int id,
    String? name,
    String? status,
    String? notes,
    List<Map<String, dynamic>>? items,
  }) {
    return remoteDataSource.updateTreatmentPlan(
      id: id,
      name: name,
      status: status,
      notes: notes,
      items: items,
    );
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<void> delete(int id) => remoteDataSource.deleteTreatmentPlan(id);

  // ── CHANGE STATUS ──────────────────────────────────────────
  Future<TreatmentPlanModel> changeStatus({
    required int id,
    required String status,
    String? reason,
  }) {
    return remoteDataSource.changeStatus(
      id: id,
      status: status,
      reason: reason,
    );
  }

  void clearCache() {}

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}

// ── Riverpod provider ────────────────────────────────────────
final treatmentPlanRepositoryProvider =
    Provider<TreatmentPlanRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TreatmentPlanRepository(
    remoteDataSource: TreatmentPlanRemoteDataSource(dio: dio),
  );
});