// lib/data/datasources/remote/clinical_records_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../models/clinical_records/clinical_summary_model.dart';

class ClinicalRecordsRemoteDataSource {
  final Dio dio;
  ClinicalRecordsRemoteDataSource({required this.dio});

  /// Fetch aggregated clinical summary (stats + recent activity)
  Future<ClinicalSummaryModel> fetchSummary() async {
    try {
      final response = await dio.get('/clinical-records/summary');
      final data = response.data['data'] as Map<String, dynamic>;
      return ClinicalSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to load clinical summary',
      );
    }
  }

  /// Fetch clinical stats only (lightweight)
  Future<ClinicalStatsModel> fetchStats() async {
    try {
      final response = await dio.get('/clinical-records/stats');
      final data = response.data['data'] as Map<String, dynamic>;
      return ClinicalStatsModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to load clinical stats',
      );
    }
  }
}