// lib/presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'components/activity_card.dart';
import 'components/schedule_card.dart';
import 'components/stat_card.dart';
import 'dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    final user = ref.watch(authStateProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Welcome Header ─────────────────────────────
          _WelcomeHeader(userName: user?.name ?? 'User'),

          const SizedBox(height: AppDimensions.paddingXL),

          // ─── Stats Cards ────────────────────────────────
          statsAsync.when(
            data: (stats) => _StatsGrid(
              cards: [
                StatCard(
                  title: 'Appointments Today',
                  value: stats.appointmentsToday.toString(),
                  trend: '↑',
                  accentColor: AppColors.success,
                  icon: Icons.calendar_month_outlined,
                ),
                StatCard(
                  title: 'New Patients',
                  value: stats.newPatients.toString(),
                  trend: '',
                  accentColor: AppColors.info,
                  icon: Icons.person_add_alt_outlined,
                ),
                StatCard(
                  title: 'Pending Reviews',
                  value: stats.pendingReviews.toString(),
                  trend: '',
                  accentColor: AppColors.warning,
                  icon: Icons.pending_actions_outlined,
                ),
                StatCard(
                  title: 'Revenue This Month',
                  value: '\$${stats.monthlyRevenue.toStringAsFixed(0)}',
                  trend: '↑12%',
                  accentColor: AppColors.primary,
                  icon: Icons.trending_up_outlined,
                ),
              ],
            ),
            loading: () => _buildStatsPlaceholder(),
            error: (e, _) => _buildStatsPlaceholder(),
          ),

          const SizedBox(height: AppDimensions.paddingXL),

          // ─── Schedule + Activity ────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;

              final schedule = appointmentsAsync.when(
                data: (appointments) => ScheduleCard(appointments),
                loading: () => _buildCardPlaceholder("Today's Schedule"),
                error: (e, _) => _buildCardPlaceholder("Today's Schedule"),
              );

              final activity = activitiesAsync.when(
                data: (activities) => ActivityCard(activities),
                loading: () => _buildCardPlaceholder('Recent Activity'),
                error: (e, _) => _buildCardPlaceholder('Recent Activity'),
              );

              if (isCompact) {
                return Column(
                  children: [
                    schedule,
                    const SizedBox(height: AppDimensions.paddingLarge),
                    activity,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: schedule),
                  const SizedBox(width: AppDimensions.paddingLarge),
                  Expanded(child: activity),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPlaceholder() {
    return _StatsGrid(
      cards: [
        StatCard(
          title: 'Appointments Today',
          value: '—',
          trend: '',
          accentColor: AppColors.success,
          icon: Icons.calendar_month_outlined,
        ),
        StatCard(
          title: 'New Patients',
          value: '—',
          trend: '',
          accentColor: AppColors.info,
          icon: Icons.person_add_alt_outlined,
        ),
        StatCard(
          title: 'Pending Reviews',
          value: '—',
          trend: '',
          accentColor: AppColors.warning,
          icon: Icons.pending_actions_outlined,
        ),
        StatCard(
          title: 'Revenue This Month',
          value: '—',
          trend: '',
          accentColor: AppColors.primary,
          icon: Icons.trending_up_outlined,
        ),
      ],
    );
  }

  Widget _buildCardPlaceholder(String label) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No data available',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome Header ────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.userName});

  final String userName;

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
              "Your schedule for today is looking busy but productive.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

        final button = ElevatedButton.icon(
          onPressed: () {},
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
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 16),
              button,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: copy),
            button,
          ],
        );
      },
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
          childAspectRatio: columns == 1 ? 3.5 : 1.9,
          children: cards,
        );
      },
    );
  }
}