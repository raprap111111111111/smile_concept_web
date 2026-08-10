// lib/data/datasources/remote/patient_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/error_message.dart';
import '../../../core/network/dio_client.dart';
import '../../../presentation/providers/patient/patient_list_provider.dart';
import '../../models/patient/patient_model.dart';

final patientRemoteDataSourceProvider =
    Provider<PatientRemoteDataSource>((ref) {
  return PatientRemoteDataSource(ref.watch(dioProvider));
});

class PatientRemoteDataSource {
  final Dio _dio;
  PatientRemoteDataSource(this._dio);

  /// `/patients` is the full-CRUD resource: User account + medical profile in
  /// one call. `/patient-profiles` is the medical-only view and registers no
  /// store or destroy, so creating through it returns 405.
  static const _basePath = '/patients';

  Future<PatientPaginatedResult> getAllPaginated({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    final offset = (page - 1) * perPage;

    final queryParams = <String, dynamic>{
      'offset': offset,
      'limit': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    debugPrint('📤 GET $_basePath  params=$queryParams');

    final response = await _dio.get(
      _basePath,
      queryParameters: queryParams,
    );

    debugPrint('📥 URL: ${response.realUri}');

    final raw = response.data;
    Map<String, dynamic>? dataMap;

    if (raw is Map && raw['data'] is Map) {
      dataMap = _toStringMap(raw['data'] as Map);
    }

    final records = _extractList(response.data);

    final patients = records
        .map((item) {
          if (item is Map) return PatientModel.fromJson(_toStringMap(item));
          return null;
        })
        .whereType<PatientModel>()
        .toList();

    debugPrint(
        '✅ Got ${patients.length} patients (page ${dataMap?['current_page']}/${dataMap?['last_page']})');

    return PatientPaginatedResult(
      patients: patients,
      currentPage: (dataMap?['current_page'] as num?)?.toInt() ?? page,
      lastPage: (dataMap?['last_page'] as num?)?.toInt() ?? 1,
      perPage: (dataMap?['per_page'] as num?)?.toInt() ?? perPage,
      total: (dataMap?['total'] as num?)?.toInt() ?? patients.length,
      hasMore: dataMap?['has_more'] == true,
    );
  }

  Future<PatientModel> getById(int id) async {
    final response = await _dio.get('$_basePath/$id');
    return PatientModel.fromJson(_extractObject(response.data));
  }

  /// Create new patient (User + Profile in one call)
  Future<PatientModel> create(Map<String, dynamic> data) async {
    debugPrint('📤 POST $_basePath  data=$data');

    try {
      final response = await _dio.post(_basePath, data: data);
      debugPrint('✅ Patient created: ${response.data}');
      return PatientModel.fromJson(_extractObject(response.data));
    } on DioException catch (e) {
      // Extract server validation errors
      final serverMessage = _extractErrorMessage(e);
      debugPrint('❌ Create failed: $serverMessage');
      throw Exception(serverMessage);
    }
  }

  Future<PatientModel> update(int id, Map<String, dynamic> data) async {
    debugPrint('📤 PUT $_basePath/$id  data=$data');

    try {
      final response = await _dio.put('$_basePath/$id', data: data);
      return PatientModel.fromJson(_extractObject(response.data));
    } on DioException catch (e) {
      final serverMessage = _extractErrorMessage(e);
      throw Exception(serverMessage);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('$_basePath/$id');
    } on DioException catch (e) {
      final serverMessage = _extractErrorMessage(e);
      throw Exception(serverMessage);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

  /// Delegates to the app-wide humanizer, which reads Laravel's validation bag
  /// and replaces unhelpful wording for status codes like 403 and 500. The old
  /// hand-rolled version returned `e.message` — Dio's internal diagnostics —
  /// whenever the body wasn't a Map.
  String _extractErrorMessage(DioException e) =>
      describeError(e, fallback: "That didn't work. Please try again.");

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

  Map<String, dynamic> _extractObject(dynamic raw) {
    Map? source;
    if (raw is Map) {
      final data = raw['data'];
      source = data is Map ? data : raw;
    }
    if (source == null) throw Exception('Unexpected response format');
    return _toStringMap(source);
  }
}