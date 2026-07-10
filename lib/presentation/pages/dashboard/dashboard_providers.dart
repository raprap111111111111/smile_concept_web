// lib/presentation/pages/dashboard/dashboard_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/models/dashboard/dashboard_stats.dart';
import '../../../core/network/dio_client.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.getStats();
  } on DioException catch (e) {
    // Endpoint doesn't exist yet — return empty stats
    if (e.response?.statusCode == 404) {
      return DashboardStats(
        appointmentsToday: 0,
        newPatients: 0,
        pendingReviews: 0,
        monthlyRevenue: 0,
      );
    }
    rethrow;
  }
});

final todayAppointmentsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.getTodayAppointments();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return [];
    rethrow;
  }
});

final recentActivitiesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  try {
    return await repo.getRecentActivities();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return [];
    rethrow;
  }
});