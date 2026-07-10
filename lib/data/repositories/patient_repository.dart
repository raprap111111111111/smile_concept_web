// lib/data/repositories/patient_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/patient/patient_list_provider.dart';
import '../datasources/remote/patient_remote_datasource.dart';
import '../models/patient/patient_model.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(patientRemoteDataSourceProvider));
});

class PatientRepository {
  final PatientRemoteDataSource _remoteDataSource;
  PatientRepository(this._remoteDataSource);

  Future<PatientPaginatedResult> getAllPaginated({
    int page = 1,
    int perPage = 10,
    String? search,
  }) =>
      _remoteDataSource.getAllPaginated(
        page: page,
        perPage: perPage,
        search: search,
      );

  // Kept for backward compat
  Future<List<PatientModel>> getAll({int page = 1, String? search}) async {
    final result = await _remoteDataSource.getAllPaginated(
      page: page,
      search: search,
    );
    return result.patients;
  }

  Future<PatientModel> getById(int id) => _remoteDataSource.getById(id);

  Future<PatientModel> create(Map<String, dynamic> data) =>
      _remoteDataSource.create(data);

  Future<PatientModel> update(int id, Map<String, dynamic> data) =>
      _remoteDataSource.update(id, data);

  Future<void> delete(int id) => _remoteDataSource.delete(id);

}