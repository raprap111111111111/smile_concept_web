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

  // ─── Helpers ────────────────────────────────────────────
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