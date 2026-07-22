import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../models/dashboard/dashboard_stats.dart';
import '../models/dashboard/recent_activity.dart';
import '../models/dashboard/today_schedule.dart';

class DashboardRepository {
  final Dio dio;

  DashboardRepository(this.dio);

  Future<DashboardStats> getStats() async {
    try {
      final response = await dio.get('/dashboard/stats');
      return DashboardStats.fromJson(_unwrap(response));
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.message ?? 'Failed to load dashboard stats',
        code: 'DASHBOARD_STATS_FAILURE',
      );
    }
  }

  Future<TodaySchedule> getTodaySchedule() async {
    try {
      final response = await dio.get('/dashboard/appointments-today');
      return TodaySchedule.fromJson(_unwrap(response));
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.message ?? 'Failed to load appointments',
        code: 'TODAY_APPOINTMENTS_FAILURE',
      );
    }
  }

  Future<RecentActivityFeed> getRecentActivity({int limit = 10}) async {
    try {
      final response = await dio.get(
        '/dashboard/recent-activity',
        queryParameters: {'limit': limit},
      );
      return RecentActivityFeed.fromJson(_unwrap(response));
    } on DioException catch (e) {
      throw ApiFailure(
        message: e.message ?? 'Failed to load activities',
        code: 'RECENT_ACTIVITIES_FAILURE',
      );
    }
  }

  /// The API wraps every payload in `{status, message, data}`; tolerate a bare
  /// body too so a proxy that unwraps it does not break the parse.
  Map<String, dynamic> _unwrap(Response response) {
    final body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }
}
