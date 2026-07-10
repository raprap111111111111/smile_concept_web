// lib/data/repositories/appointment_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/local/appointment_local_datasource.dart';
import '../datasources/remote/appointment_remote_datasource.dart';
import '../models/appointment/appointment_model.dart';
import '../models/appointment/appointment_request.dart';
import '../models/appointment/availability_model.dart';
import '../models/appointment/paginated_appointment_result.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(
    remote: ref.watch(appointmentRemoteDataSourceProvider),
    local: ref.watch(appointmentLocalDataSourceProvider),
  );
});

class AppointmentRepository {
  final AppointmentRemoteDataSource _remote;
  final AppointmentLocalDataSource _local;

  AppointmentRepository({
    required AppointmentRemoteDataSource remote,
    required AppointmentLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  /// 🔐 Backend handles permission filtering:
  /// - Patient (no viewAny) → backend forces where('user_id', authUserId)
  /// - Admin/Staff (viewAny) → backend shows all
  Future<PaginatedAppointmentResult> getAppointments({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    int? doctorId,
    int? branchId,
    int? userId,
    String? startDate,
    String? endDate,
  }) async {
    // ✅ Convert page → offset
    final offset = (page - 1) * pageSize;

    return _remote.getAppointments(
      limit: pageSize,
      offset: offset,
      search: search,
      status: status,
      doctorId: doctorId,
      branchId: branchId,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, Map<String, int>>> getCalendarCounts({
    required DateTime month,
    String? status,
    int? doctorId,
    int? branchId,
    int? userId,
  }) {
    return _remote.getCalendarCounts(
      month: month,
      status: status,
      doctorId: doctorId?.toString(),
      branchId: branchId?.toString(),
      patientId: userId?.toString(),
    );
  }

  Future<AppointmentModel> getAppointment(int id) async {
    try {
      final result = await _remote.getAppointmentById(id.toString());
      await _local.cacheAppointment(result);
      return result;
    } catch (e) {
      final cached = await _local.getCachedAppointment(id.toString());
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<AppointmentModel> createAppointment(AppointmentRequest request) async {
    final result = await _remote.createAppointment(request);
    await _local.cacheAppointment(result);
    return result;
  }

  Future<AppointmentModel> updateAppointment({
    required int id,
    required AppointmentRequest request,
  }) async {
    final result = await _remote.updateAppointment(id.toString(), request);
    await _local.cacheAppointment(result);
    return result;
  }

  Future<void> deleteAppointment(int id) async {
    await _remote.cancelAppointment(id.toString());
    await _local.deleteAppointment(id.toString());
  }

  Future<AvailabilityResponse> getAvailableSlots({
    required int doctorId,
    required int branchId,
    required DateTime date,
  }) {
    return _remote.getAvailableSlots(
      doctorId: doctorId.toString(),
      branchId: branchId.toString(),
      date: date,
    );
  }

  Future<AppointmentModel> updateAppointmentStatus({
    required int id,
    required String status,
    String? cancellationReason,
  }) async {
    final result = await _remote.updateAppointmentStatus(
      id: id,
      status: status,
      cancellationReason: cancellationReason,
    );
    await _local.cacheAppointment(result);
    return result;
  }
}