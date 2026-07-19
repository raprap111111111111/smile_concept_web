// lib/presentation/providers/patient_attachment/patients_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/models/patient_attachment/patient_summary_model.dart';
import '/data/repositories/patient_repository.dart';

// ═══════════════════════════════════════════════════════
// ✅ ALL PATIENTS (uses existing PatientRepository)
// (for upload form selector)
// ═══════════════════════════════════════════════════════

final allPatientsProvider =
    FutureProvider<List<PatientSummary>>((ref) async {
  try {
    final repo = ref.watch(patientRepositoryProvider);
    final result = await repo.getAllPaginated(page: 1, perPage: 200);

    debugPrint('✅ Loaded ${result.patients.length} patients');

    return result.patients
        .map((p) => PatientSummary(
              id: p.userId,                    // ✅ FIXED: was p.id
              name: p.name,
              email: p.email,
              profilePhoto: p.profilePhotoUrl,
            ))
        .toList();
  } catch (e) {
    debugPrint('❌ allPatientsProvider error: $e');
    rethrow;
  }
});

// ═══════════════════════════════════════════════════════
// ✅ SEARCH PATIENTS (server-side)
// ═══════════════════════════════════════════════════════

final searchPatientsProvider = FutureProvider.autoDispose
    .family<List<PatientSummary>, String>((ref, query) async {
  try {
    final repo = ref.watch(patientRepositoryProvider);
    final result = await repo.getAllPaginated(
      page: 1,
      perPage: 50,
      search: query.isEmpty ? null : query,
    );

    return result.patients
        .map((p) => PatientSummary(
              id: p.userId,                    // ✅ FIXED: was p.id
              name: p.name,
              email: p.email,
              profilePhoto: p.profilePhotoUrl,
            ))
        .toList();
  } catch (e) {
    debugPrint('❌ searchPatientsProvider error: $e');
    rethrow;
  }
});