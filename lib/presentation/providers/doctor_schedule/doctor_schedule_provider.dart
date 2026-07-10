// lib/presentation/providers/doctor_schedule/doctor_schedule_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/repositories/doctor_schedule_repository.dart';

final doctorScheduleRepositoryProvider = Provider<DoctorScheduleRepository>((ref) {
  return DoctorScheduleRepository(ref.watch(dioProvider));
});