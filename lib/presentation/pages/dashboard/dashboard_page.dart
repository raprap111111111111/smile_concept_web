// lib/presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/dashboard/dashboard_stats.dart';
import '../../../data/models/dashboard/recent_activity.dart';
import '../../../data/models/dashboard/today_schedule.dart';
import '../../providers/auth/auth_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/chart_palette.dart';
import 'components/activity_card.dart';
import 'components/charts/appointments_trend_chart.dart';
import 'components/charts/chart_card.dart';
import 'components/charts/hourly_appointments_chart.dart';
import 'components/charts/new_patients_chart.dart';
import 'components/schedule_card.dart';
import 'components/stat_card.dart';
import 'dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    final user = ref.watch(authStateProvider).user;

    final stats = statsAsync.valueOrNull ?? DashboardStats.empty;
    final schedule = scheduleAsync.valueOrNull ?? TodaySchedule.empty;
    final activity = activityAsync.valueOrNull ?? RecentActivityFeed.empty;

    final hasError = statsAsync.hasError ||
        scheduleAsync.hasError ||
        activityAsync.hasError;

    return RefreshIndicator(
      onRefresh: () async => refreshDashboard(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeHeader(
              userName: user?.name ?? 'User',
              appointmentsToday: stats.appointmentsToday,
              isLoading: statsAsync.isLoading,
              onViewCalendar: () =>
                  context.goNamed(RouteNames.appointments),
              onRefresh: () => refreshDashboard(ref),
            ),

            if (hasError) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _ErrorBanner(onRetry: () => refreshDashboard(ref)),
            ],

            const SizedBox(height: AppDimensions.paddingXL),

            // ─── Stat tiles ─────────────────────────────────
            _StatsGrid(
              cards: [
                StatCard(
                  title: 'Appointments Today',
                  value: statsAsync.isLoading
                      ? '—'
                      : stats.appointmentsToday.toString(),
                  delta: statsAsync.hasValue
                      ? stats.appointmentsTodayDelta
                      : null,
                  deltaPeriod: 'vs yesterday',
                  accentColor: ChartPalette.primarySeries,
                  icon: Icons.calendar_month_outlined,
                  trend: stats.appointmentsTrend
                      .map((point) => point.total)
                      .toList(),
                ),
                StatCard(
                  title: 'New Patients',
                  value:
                      statsAsync.isLoading ? '—' : stats.newPatients.toString(),
                  delta:
                      statsAsync.hasValue ? stats.newPatientsDelta : null,
                  deltaPeriod: 'vs last month',
                  accentColor: ChartPalette.statusConfirmed,
                  icon: Icons.person_add_alt_outlined,
                  trend:
                      stats.newPatientsTrend.map((p) => p.count).toList(),
                ),
                StatCard(
                  title: 'Pending Reviews',
                  value: statsAsync.isLoading
                      ? '—'
                      : stats.pendingReviews.toString(),
                  accentColor: ChartPalette.statusPending,
                  icon: Icons.pending_actions_outlined,
                  // Fewer unreviewed appointments is the good direction.
                  upIsGood: false,
                ),
                StatCard(
                  title: 'Revenue This Month',
                  value: statsAsync.isLoading
                      ? '—'
                      : '\$${stats.monthlyRevenue.toStringAsFixed(0)}',
                  delta: statsAsync.hasValue
                      ? stats.monthlyRevenueDelta
                      : null,
                  deltaPeriod: 'vs last month',
                  accentColor: ChartPalette.statusCompleted,
                  icon: Icons.trending_up_outlined,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // ─── Charts ─────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 900;

                final hourly = ChartCard(
                  title: 'Appointments Today',
                  subtitle: 'Bookings by start hour',
                  height: 200,
                  isEmpty: stats.appointmentsTodayByHour.isEmpty,
                  emptyMessage: statsAsync.isLoading
                      ? 'Loading…'
                      : 'Nothing booked today',
                  trailing: statsAsync.hasValue
                      ? DeltaBadge(
                          delta: stats.appointmentsTodayDelta,
                          period: 'vs yesterday',
                        )
                      : null,
                  child: HourlyAppointmentsChart(
                    points: stats.appointmentsTodayByHour,
                  ),
                );

                final newPatients = ChartCard(
                  title: 'New Patients',
                  subtitle: 'Registrations per month, last 6 months',
                  height: 200,
                  isEmpty: stats.newPatientsByMonth.isEmpty,
                  emptyMessage:
                      statsAsync.isLoading ? 'Loading…' : 'No registrations yet',
                  trailing: statsAsync.hasValue
                      ? DeltaBadge(
                          delta: stats.newPatientsDelta,
                          period: 'vs last month',
                        )
                      : null,
                  child: NewPatientsChart(points: stats.newPatientsByMonth),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      hourly,
                      const SizedBox(height: AppDimensions.paddingLarge),
                      newPatients,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: hourly),
                    const SizedBox(width: AppDimensions.paddingLarge),
                    Expanded(child: newPatients),
                  ],
                );
              },
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            ChartCard(
              title: 'Appointment Volume',
              subtitle: 'Total bookings per day, last 14 days',
              height: 200,
              isEmpty: stats.appointmentsTrend.isEmpty,
              emptyMessage:
                  statsAsync.isLoading ? 'Loading…' : 'No bookings on record',
              footer: TrendCaption(points: stats.appointmentsTrend),
              child: AppointmentsTrendChart(points: stats.appointmentsTrend),
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // ─── Schedule + Activity ────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 900;

                final scheduleCard = ScheduleCard(
                  schedule,
                  onBookNew: () => context.goNamed(RouteNames.bookAppointment),
                );
                final activityCard = ActivityCard(activity);

                if (isCompact) {
                  return Column(
                    children: [
                      scheduleCard,
                      const SizedBox(height: AppDimensions.paddingLarge),
                      activityCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: scheduleCard),
                    const SizedBox(width: AppDimensions.paddingLarge),
                    Expanded(child: activityCard),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Header ────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.userName,
    required this.appointmentsToday,
    required this.isLoading,
    required this.onViewCalendar,
    required this.onRefresh,
  });

  final String userName;
  final int appointmentsToday;
  final bool isLoading;
  final VoidCallback onViewCalendar;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, $userName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              // Say what today actually looks like rather than guessing at it.
              isLoading
                  ? 'Loading your day…'
                  : appointmentsToday == 0
                      ? 'Nothing on the books for today.'
                      : appointmentsToday == 1
                          ? 'You have 1 appointment today.'
                          : 'You have $appointmentsToday appointments today.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: onViewCalendar,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('View Calendar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 16),
              actions,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: copy),
            actions,
          ],
        );
      },
    );
  }
}

/// Shown when any of the three dashboard calls failed — the cards below still
/// render with whatever loaded, so the banner explains the gap.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD03B3B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: const Color(0xFFD03B3B).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFD03B3B)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Some dashboard data could not be loaded.',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Color(0xFFD03B3B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Responsive Stats Grid ─────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        if (constraints.maxWidth < 600) {
          columns = 1;
        } else if (constraints.maxWidth < 1000) {
          columns = 2;
        } else {
          columns = 4;
        }

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          // Taller than before: the tiles now carry a sparkline.
          childAspectRatio: columns == 1 ? 3.0 : 1.55,
          children: cards,
        );
      },
    );
  }
}
