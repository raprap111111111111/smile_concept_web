// lib/data/datasources/remote/appointment_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment/appointment_model.dart';
import '../../models/appointment/appointment_request.dart';
import '../../models/appointment/availability_model.dart';
import '../../models/appointment/paginated_appointment_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/api_config.dart';

final appointmentRemoteDataSourceProvider =
    Provider<AppointmentRemoteDataSource>((ref) {
  return AppointmentRemoteDataSource(ref.watch(dioProvider));
});

class AppointmentRemoteDataSource {
  final Dio _dio;

  AppointmentRemoteDataSource(this._dio);

  // ─── GET /appointments (paginated) ──────────────────────────────
  Future<PaginatedAppointmentResult> getAppointments({
    int limit = 10,
    int offset = 0,
    int? userId,
    int? doctorId,
    int? branchId,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.getAppointments,
        queryParameters: {
          // ✅ Backend uses offset/limit NOT page/per_page
          'limit': limit,
          'offset': offset,
          if (userId != null) 'user_id': userId,
          if (doctorId != null) 'doctor_id': doctorId,
          if (branchId != null) 'branch_id': branchId,
          if (status != null) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'];

      List items = [];
      int total = 0;
      int currentPage = 1;
      int lastPage = 1;
      bool hasNextPage = false;

      if (rawData is Map<String, dynamic>) {
        // ✅ Backend returns 'records' not 'data'
        items = rawData['records'] as List? ?? [];
        total = rawData['total'] ?? items.length;
        currentPage = rawData['current_page'] ?? 1;
        lastPage = rawData['last_page'] ?? 1;
        // ✅ Use has_more directly from backend
        hasNextPage = rawData['has_more'] ?? false;
      } else if (rawData is List) {
        items = rawData;
        total = items.length;
      }

      return PaginatedAppointmentResult(
        data: items
            .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: total,
        currentPage: currentPage,
        lastPage: lastPage,
        hasNextPage: hasNextPage,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, Map<String, int>>> getCalendarCounts({
    required DateTime month,
    String? status,
    String? doctorId,
    String? branchId,
    String? patientId,
  }) async {
    try {
      final monthString =
          '${month.year.toString().padLeft(4, '0')}-'
          '${month.month.toString().padLeft(2, '0')}';

      final response = await _dio.get(
        '${ApiConfig.getAppointments}/calendar-counts',
        queryParameters: {
          'month': monthString,
          if (status != null && status.isNotEmpty) 'status': status,
          if (doctorId != null) 'doctor_id': doctorId,
          if (branchId != null) 'branch_id': branchId,
          if (patientId != null) 'user_id': patientId,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] as Map<String, dynamic>? ?? {};

      return rawData.map((date, value) {
        if (value is Map) {
          return MapEntry(date, {
            'pending': _asInt(value['pending']),
            'confirmed': _asInt(value['confirmed']),
            'completed': _asInt(value['completed']),
            'cancelled': _asInt(value['cancelled']),
            'total': _asInt(value['total']),
          });
        }

        final count = _asInt(value);
        return MapEntry(date, {
          'pending': count,
          'confirmed': 0,
          'completed': 0,
          'cancelled': 0,
          'total': count,
        });
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ─── GET /appointments/:id ───────────────────────────────────────
  Future<AppointmentModel> getAppointmentById(String appointmentId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getAppointments}/$appointmentId',
      );
      return AppointmentModel.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── POST /appointments ──────────────────────────────────────────
  Future<AppointmentModel> createAppointment(
    AppointmentRequest request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.getAppointments,
        data: request.toJson(),
      );
      return AppointmentModel.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── PUT /appointments/:id ───────────────────────────────────────
  Future<AppointmentModel> updateAppointment(
    String id,
    AppointmentRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.getAppointments}/$id',
        data: request.toJson(),
      );
      return AppointmentModel.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── DELETE /appointments/:id ────────────────────────────────────
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _dio.delete(
        '${ApiConfig.getAppointments}/$appointmentId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── GET available slots ─────────────────────────────────────────
  Future<AvailabilityResponse> getAvailableSlots({
    required String doctorId,
    required String branchId,
    required DateTime date,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.getAvailableSlots,
        queryParameters: {
          'doctor_id': doctorId,
          'branch_id': branchId,
          'date': date.toIso8601String().split('T')[0],
        },
      );
      return AvailabilityResponse.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── PATCH /appointments/:id/status ─────────────────────────────
  Future<AppointmentModel> updateAppointmentStatus({
    required int id,
    required String status,
    String? cancellationReason,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiConfig.getAppointments}/$id/status',
        data: {
          'status': status,
          if (cancellationReason != null && cancellationReason.isNotEmpty)
            'cancellation_reason': cancellationReason,
        },
      );
      return AppointmentModel.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Error Handler ───────────────────────────────────────────────
  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] 
        ?? e.message 
        ?? 'Unknown error occurred';

    switch (statusCode) {
      case 401:
        return Exception('Unauthorized: $message');
      case 403:
        return Exception('Forbidden: $message');
      case 404:
        return Exception('Not found: $message');
      case 422:
        final errors = e.response?.data?['errors'];
        if (errors != null) {
          final firstError = (errors as Map).values.first;
          return Exception(
            firstError is List ? firstError.first : firstError.toString(),
          );
        }
        return Exception(message);
      default:
        return Exception(message);
    }
  }
}