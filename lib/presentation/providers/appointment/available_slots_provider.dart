// lib/presentation/providers/appointment/available_slots_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/models/appointment/availability_model.dart';

final availableSlotsProvider = FutureProvider.family<
    AvailabilityResponse,
    AvailableSlotsParams>((ref, params) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAvailableSlots(
    doctorId: params.doctorId,   // ✅ now int → int
    branchId: params.branchId,   // ✅ now int → int
    date: params.date,
  );
});

class AvailableSlotsParams {
  final int doctorId;   // ✅ Changed String → int
  final int branchId;   // ✅ Changed String → int
  final DateTime date;

  const AvailableSlotsParams({
    required this.doctorId,
    required this.branchId,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableSlotsParams &&
          runtimeType == other.runtimeType &&
          doctorId == other.doctorId &&
          branchId == other.branchId &&
          date == other.date;

  @override
  int get hashCode =>
      doctorId.hashCode ^ branchId.hashCode ^ date.hashCode;
}