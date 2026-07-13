// lib/data/repositories/treatment_plan_repository.dart

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

  Future<TreatmentPlanResult> getTreatmentPlans({
    int page = 1,
    int? patientId,
    int? doctorId,
    String? status,
    bool forceRefresh = false,
  }) async {
    final raw = await remoteDataSource.fetchTreatmentPlans(
      page:      page,
      patientId: patientId,
      doctorId:  doctorId,
      status:    status,
    );

    final data       = raw['data'] as Map<String, dynamic>;
    final pagination = data['meta'] as Map<String, dynamic>?
                    ?? data['pagination'] as Map<String, dynamic>?
                    ?? {};
    final items      = data['data'] as List<dynamic>? ?? [];

    final plans = items
        .map((e) => TreatmentPlanModel.fromJson(
            _toMap(e as Map)))
        .toList();

    return TreatmentPlanResult(
      plans:       plans,
      currentPage: (pagination['current_page'] as num?)?.toInt() ?? 1,
      lastPage:    (pagination['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  Future<TreatmentPlanModel> getTreatmentPlanById(int id) async {
    return remoteDataSource.fetchTreatmentPlanById(id);
  }

  void clearCache() {}

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}