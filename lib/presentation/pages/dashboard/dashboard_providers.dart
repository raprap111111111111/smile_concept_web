// lib/presentation/pages/dashboard/dashboard_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/dashboard/dashboard_stats.dart';
import '../../../data/models/dashboard/recent_activity.dart';
import '../../../data/models/dashboard/today_schedule.dart';
import '../../../data/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getStats();
});

final todayScheduleProvider =
    FutureProvider.autoDispose<TodaySchedule>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getTodaySchedule();
});

final recentActivityProvider =
    FutureProvider.autoDispose<RecentActivityFeed>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getRecentActivity(limit: 10);
});

/// Pull-to-refresh / manual refresh for the whole dashboard.
void refreshDashboard(WidgetRef ref) {
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(todayScheduleProvider);
  ref.invalidate(recentActivityProvider);
}
