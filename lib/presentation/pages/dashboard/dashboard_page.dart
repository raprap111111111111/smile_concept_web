// lib/presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth/auth_provider.dart'; // ✅ use auth state directly
import 'dashboard_providers.dart';
import 'components/stat_card.dart';
import 'components/schedule_card.dart';
import 'components/activity_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    final user = ref.watch(authStateProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Welcome Header ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, ${user?.name ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your schedule for today is looking busy but productive.",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('View Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ─── Stats Cards ────────────────────────────────
          statsAsync.when(
            data: (stats) => GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.3,
              children: [
                StatCard(
                  'Appointments Today',
                  stats.appointmentsToday.toString(),
                  '↑',
                  Colors.green,
                ),
                StatCard(
                  'New Patients',
                  stats.newPatients.toString(),
                  '',
                  Colors.blue,
                ),
                StatCard(
                  'Pending Reviews',
                  stats.pendingReviews.toString(),
                  '',
                  Colors.orange,
                ),
                StatCard(
                  'Revenue This Month',
                  '\$${stats.monthlyRevenue.toStringAsFixed(0)}',
                  '↑12%',
                  Colors.purple,
                ),
              ],
            ),
            loading: () => _buildStatsPlaceholder(),
            error: (e, _) => _buildStatsPlaceholder(),
          ),

          const SizedBox(height: 32),

          // ─── Schedule + Activity ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: appointmentsAsync.when(
                  data: (appointments) => ScheduleCard(appointments),
                  loading: () => _buildCardPlaceholder('Schedule'),
                  error: (e, _) => _buildCardPlaceholder('Schedule'),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: activitiesAsync.when(
                  data: (activities) => ActivityCard(activities),
                  loading: () => _buildCardPlaceholder('Activity'),
                  error: (e, _) => _buildCardPlaceholder('Activity'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Placeholder for missing backend data ────────────────
  Widget _buildStatsPlaceholder() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.3,
      children: const [
        StatCard('Appointments Today', '—', '', Colors.green),
        StatCard('New Patients', '—', '', Colors.blue),
        StatCard('Pending Reviews', '—', '', Colors.orange),
        StatCard('Revenue This Month', '—', '', Colors.purple),
      ],
    );
  }

  Widget _buildCardPlaceholder(String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}