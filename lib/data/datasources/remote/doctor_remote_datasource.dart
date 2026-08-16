import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../models/doctor/doctor_simple_model.dart';

final doctorRemoteDataSourceProvider = Provider<DoctorRemoteDataSource>((ref) {
  return DoctorRemoteDataSource(ref.watch(dioProvider));
});

class DoctorRemoteDataSource {
  final Dio _dio;
  DoctorRemoteDataSource(this._dio);

  static const _basePath = '/doctors';

  // ═══════════════════════════════════════════════════════════
  // GET ALL
  // ═══════════════════════════════════════════════════════════
  Future<List<DoctorSimpleModel>> getAll() async {
    debugPrint('📤 GET $_basePath');

    final response = await _dio.get(
      _basePath,
      queryParameters: {'limit': 100}, // fetch enough for dropdown
    );

    debugPrint('📥 Doctors response received');

    final records = _extractList(response.data);

    final doctors = records
        .map((item) {
          if (item is Map) {
            return DoctorSimpleModel.fromJson(_toStringMap(item));
          }
          return null;
        })
        .whereType<DoctorSimpleModel>()
        .toList();

    debugPrint('✅ Loaded ${doctors.length} doctors');
    return doctors;
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ NEW — GET BY ID (for detail page)
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getById(int id) async {
    debugPrint('📤 GET $_basePath/$id');

    final response = await _dio.get('$_basePath/$id');

    debugPrint('📥 Doctor detail response received');

    // Handle both wrapped { data: {...} } and direct {...} responses
    final raw = response.data;
    Map<String, dynamic> data;

    if (raw is Map && raw['data'] is Map) {
      data = _toStringMap(raw['data'] as Map);
    } else if (raw is Map) {
      data = _toStringMap(raw);
    } else {
      throw Exception('Unexpected response format for doctor #$id');
    }

    debugPrint('✅ Loaded doctor #$id');
    return data;
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> _toStringMap(Map source) {
    final result = <String, dynamic>{};
    source.forEach((k, v) => result[k.toString()] = v);
    return result;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
      if (data is Map) {
        if (data['records'] is List) return data['records'] as List;
        if (data['data'] is List) return data['data'] as List;
        if (data['items'] is List) return data['items'] as List;
      }
    }
    return [];
  }
}