// lib/data/repositories/doctor_schedule_repository.dart

import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../models/doctor_schedule/doctor_schedule_model.dart';

class DoctorScheduleRepository {
  final Dio _dio;

  DoctorScheduleRepository(this._dio);

  // ─── GET /api/v1/doctor-schedules ────────────────────────────────────────

  Future<PaginatedSchedules> getSchedules({
    int page = 1,
    int perPage = 15,
    int? doctorId,
    int? branchId,
    int? dayOfWeek,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final response = await _dio.get(
        '/doctor-schedules',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (doctorId != null) 'doctor_id': doctorId,
          if (branchId != null) 'branch_id': branchId,
          if (dayOfWeek != null) 'day_of_week': dayOfWeek,
          if (sortBy != null) 'sort_by': sortBy,
          if (sortDirection != null) 'sort_direction': sortDirection,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final paginationMeta = body['data'] as Map<String, dynamic>;
      final rawList = paginationMeta['records'] as List<dynamic>;

      return PaginatedSchedules(
        data: rawList
            .map((e) =>
                DoctorScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPage: paginationMeta['current_page'] ?? 1,
        lastPage: paginationMeta['last_page'] ?? 1,
        total: paginationMeta['total'] ?? 0,
        perPage: paginationMeta['per_page'] ?? perPage,
        hasMore: paginationMeta['has_more'] ?? false,
      );
    } on DioException catch (e) {
      throw ApiFailure(
        message:
            e.response?.data?['message'] ?? 'Failed to load schedules',
        code: 'SCHEDULES_FETCH_ERROR',
      );
    }
  }

  // ─── GET /api/v1/doctor-schedules/{id} ───────────────────────────────────

  Future<DoctorScheduleModel> getSchedule(int id) async {
    try {
      final response = await _dio.get('/doctor-schedules/$id');
      final body = response.data as Map<String, dynamic>;
      return DoctorScheduleModel.fromJson(
          body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.response?.data?['message'] ?? 'Failed to load schedule',
        code: 'SCHEDULE_FETCH_ERROR',
      );
    }
  }

  // ─── POST /api/v1/doctor-schedules ───────────────────────────────────────

  Future<DoctorScheduleModel> createSchedule({
    required int doctorId,
    required int branchId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _dio.post(
        '/doctor-schedules',
        data: {
          'doctor_id': doctorId,
          'branch_id': branchId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return DoctorScheduleModel.fromJson(
          body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = e.response?.data as Map<String, dynamic>?;
        throw ValidationException(
          message: data?['message'] ?? 'Validation failed',
          errors: (data?['errors'] as Map<String, dynamic>?) ?? {},
        );
      }
      throw ApiFailure(
        message:
            e.response?.data?['message'] ?? 'Failed to create schedule',
        code: 'SCHEDULE_CREATE_ERROR',
      );
    }
  }

  // ─── ✅ BULK CREATE — loops through days ─────────────────────────────────

  Future<List<DoctorScheduleModel>> createBulkSchedules({
    required int doctorId,
    required int branchId,
    required List<int> daysOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final results = <DoctorScheduleModel>[];
    final errors = <String>[];

    for (final day in daysOfWeek) {
      try {
        final schedule = await createSchedule(
          doctorId: doctorId,
          branchId: branchId,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
        );
        results.add(schedule);
      } on ValidationException catch (e) {
        final dayName = _dayName(day);
        final msg = e.errors.values.expand((v) => v as List).join(', ');
        errors.add('$dayName: $msg');
      } catch (e) {
        final dayName = _dayName(day);
        errors.add('$dayName: ${e.toString()}');
      }
    }

    // All failed → throw
    if (results.isEmpty && errors.isNotEmpty) {
      throw ApiFailure(
        message: errors.join('\n'),
        code: 'BULK_SCHEDULE_ERROR',
      );
    }

    // Some failed → partial success
    if (errors.isNotEmpty) {
      throw PartialSuccessException(
        createdSchedules: results,
        errors: errors,
      );
    }

    return results;
  }

  String _dayName(int day) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return day >= 0 && day < 7 ? days[day] : 'Day $day';
  }

  // ─── PUT /api/v1/doctor-schedules/{id} ───────────────────────────────────

  Future<DoctorScheduleModel> updateSchedule({
    required int id,
    int? doctorId,
    int? branchId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final response = await _dio.put(
        '/doctor-schedules/$id',
        data: {
          if (doctorId != null) 'doctor_id': doctorId,
          if (branchId != null) 'branch_id': branchId,
          if (dayOfWeek != null) 'day_of_week': dayOfWeek,
          if (startTime != null) 'start_time': startTime,
          if (endTime != null) 'end_time': endTime,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return DoctorScheduleModel.fromJson(
          body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = e.response?.data as Map<String, dynamic>?;
        throw ValidationException(
          message: data?['message'] ?? 'Validation failed',
          errors: (data?['errors'] as Map<String, dynamic>?) ?? {},
        );
      }
      throw ApiFailure(
        message:
            e.response?.data?['message'] ?? 'Failed to update schedule',
        code: 'SCHEDULE_UPDATE_ERROR',
      );
    }
  }

  // ─── DELETE /api/v1/doctor-schedules/{id} ────────────────────────────────

  Future<void> deleteSchedule(int id) async {
    try {
      await _dio.delete('/doctor-schedules/$id');
    } on DioException catch (e) {
      throw ApiFailure(
        message:
            e.response?.data?['message'] ?? 'Failed to delete schedule',
        code: 'SCHEDULE_DELETE_ERROR',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Exceptions
// ═══════════════════════════════════════════════════════════════════════════════

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic> errors;

  const ValidationException({
    required this.message,
    required this.errors,
  });

  @override
  String toString() => message;
}

// ✅ New: Partial success — some created, some failed
class PartialSuccessException implements Exception {
  final List<DoctorScheduleModel> createdSchedules;
  final List<String> errors;

  const PartialSuccessException({
    required this.createdSchedules,
    required this.errors,
  });

  @override
  String toString() =>
      'Created ${createdSchedules.length} schedule(s). Errors:\n${errors.join('\n')}';
}