// lib/presentation/providers/patient/patient_search_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/repositories/patient_repository.dart';

// Family provider - searches patients based on query
final patientSearchProvider = FutureProvider.autoDispose
    .family<List<PatientModel>, String>((ref, query) async {
  final repo = ref.watch(patientRepositoryProvider);
  final result = await repo.getAllPaginated(
    page: 1,
    perPage: 20,
    search: query.isEmpty ? null : query,
  );
  return result.patients;
});