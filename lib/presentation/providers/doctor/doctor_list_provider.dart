// lib/presentation/providers/doctor/doctor_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/doctor_remote_datasource.dart';
import '../../../data/models/doctor/doctor_simple_model.dart';

// ─── Simple provider that fetches all doctors ────────────────
final doctorSimpleListProvider =
    FutureProvider.autoDispose<List<DoctorSimpleModel>>((ref) async {
  final datasource = ref.watch(doctorRemoteDataSourceProvider);
  return datasource.getAll();
});

// ✅ NEW — Fetches a single doctor by ID (for the detail page)
final doctorDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
  final datasource = ref.watch(doctorRemoteDataSourceProvider);
  return datasource.getById(id);
});