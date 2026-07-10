// lib/presentation/providers/doctor_schedule/schedule_form_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/doctor_schedule/branch_option_model.dart';
import '../../../data/models/doctor_schedule/doctor_option_model.dart';

// ─── Fetch Doctors List ───────────────────────────────────────────────────────
final doctorsListProvider =
    FutureProvider.autoDispose<List<DoctorOption>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/doctors', queryParameters: {'limit': 100});

  final body = response.data;
  final data = body['data'];

  List rawList;
  if (data is Map && data['records'] is List) {
    rawList = data['records'];
  } else if (data is List) {
    rawList = data;
  } else {
    rawList = [];
  }

  return rawList
      .map((e) => DoctorOption.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

// ─── Fetch Branches List ──────────────────────────────────────────────────────
final branchesListProvider =
    FutureProvider.autoDispose<List<BranchOption>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/branches', queryParameters: {'limit': 100});

  final body = response.data;
  final data = body['data'];

  List rawList;
  if (data is Map && data['records'] is List) {
    rawList = data['records'];
  } else if (data is List) {
    rawList = data;
  } else {
    rawList = [];
  }

  return rawList
      .map((e) => BranchOption.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});