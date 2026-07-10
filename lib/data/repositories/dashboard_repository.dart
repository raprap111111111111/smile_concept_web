import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../models/dashboard/dashboard_stats.dart';

class DashboardRepository {
  final Dio dio;

  DashboardRepository(this.dio);

  Future<DashboardStats> getStats() async {
    try {
      final response = await dio.get('/dashboard/stats');
      return DashboardStats.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.message ?? 'Failed to load dashboard stats',
        code: 'DASHBOARD_STATS_FAILURE',   // ✅ Added
      );
    }
  }

  Future<List<dynamic>> getTodayAppointments() async {
    try {
      final response = await dio.get('/appointments/today');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.message ?? 'Failed to load appointments',
        code: 'TODAY_APPOINTMENTS_FAILURE',   // ✅ Added
      );
    }
  }

  Future<List<dynamic>> getRecentActivities() async {
    try {
      final response = await dio.get('/activities/recent');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.message ?? 'Failed to load activities',
        code: 'RECENT_ACTIVITIES_FAILURE',   // ✅ Added
      );
    }
  }
}