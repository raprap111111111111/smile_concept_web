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

/// Panels a `dashboard.stale` broadcast can ask for. Values match the scope
/// constants on the Laravel DashboardCountersStale event.
class DashboardScope {
  const DashboardScope._();

  static const String stats = 'stats';
  static const String schedule = 'schedule';
  static const String activity = 'activity';
}

/// Pull-to-refresh / manual refresh for the whole dashboard.
void refreshDashboard(WidgetRef ref) {
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(todayScheduleProvider);
  ref.invalidate(recentActivityProvider);
}

/// Same thing from a provider context.
///
/// [refreshDashboard] takes a `WidgetRef` and Riverpod 2 has no shared
/// supertype with `Ref`, so RealtimeBridge cannot call it. Passing [scopes]
/// refetches only the named panels; omitting it refetches all three.
void invalidateDashboard(Ref ref, {Set<String>? scopes}) {
  if (scopes == null || scopes.contains(DashboardScope.stats)) {
    ref.invalidate(dashboardStatsProvider);
  }
  if (scopes == null || scopes.contains(DashboardScope.schedule)) {
    ref.invalidate(todayScheduleProvider);
  }
  if (scopes == null || scopes.contains(DashboardScope.activity)) {
    ref.invalidate(recentActivityProvider);
  }
}
