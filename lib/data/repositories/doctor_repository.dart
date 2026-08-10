import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

class DoctorRepository {
  final Dio dio;

  DoctorRepository(this.dio);

  Future<List<Map<String, dynamic>>> getDoctors({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get('/doctors', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      });

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
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to load doctors'),
        code: 'DOCTORS_FETCH_ERROR',
        statusCode: errorStatusCode(e),
      );
    }
  }

  Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/doctors', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to create doctor'),
        code: 'DOCTOR_CREATE_ERROR',
        statusCode: errorStatusCode(e),
      );
    }
  }

  Future<Map<String, dynamic>> updateDoctor(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('/doctors/$id', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to update doctor'),
        code: 'DOCTOR_UPDATE_ERROR',
        statusCode: errorStatusCode(e),
      );
    }
  }

  Future<void> deleteDoctor(int id) async {
    try {
      await dio.delete('/doctors/$id');
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to delete doctor'),
        code: 'DOCTOR_DELETE_ERROR',
        statusCode: errorStatusCode(e),
      );
    }
  }
}

// Providers
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioProvider));
});

final doctorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(doctorRepositoryProvider);
  return repo.getDoctors();
});