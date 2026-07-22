// lib/presentation/pages/dashboard/components/activity_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/dashboard/recent_activity.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import 'charts/activity_trend_chart.dart';

/// Recent audit-log entries, headed by a two-week volume strip so a quiet or
/// unusually busy stretch is visible before reading any single row.
class ActivityCard extends StatelessWidget {
  const ActivityCard(this.feed, {super.key});

  final RecentActivityFeed feed;

  @override
  Widget build(BuildContext context) {
    final activities = feed.activities;

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
            'Recent Activity',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Recorded events, last 14 days',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (feed.byDay.length >= 2) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ActivityTrendChart(points: feed.byDay),
            ),
          ],
          const SizedBox(height: 20),
          if (activities.isEmpty)
            const _EmptyState(
              icon: Icons.history_outlined,
              message: 'No recent activity',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.line,
                height: 20,
              ),
              itemBuilder: (context, index) => _ActivityTile(activities[index]),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(this.activity);

  final ActivityEntry activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.accentWithOpacity(0.35),
          radius: 18,
          child: Icon(
            _iconForAction(activity.action),
            color: AppColors.primaryDark,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.patientName,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          activity.timeAgo,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _iconForAction(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Icons.add;
      case 'updated':
        return Icons.edit_outlined;
      case 'deleted':
        return Icons.delete_outline;
      default:
        return Icons.person;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Icon(icon, color: AppColors.textTertiary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
