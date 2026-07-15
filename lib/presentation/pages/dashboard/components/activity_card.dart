// lib/presentation/pages/dashboard/components/activity_card.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ActivityCard extends StatelessWidget {
  final List<dynamic> activities;

  const ActivityCard(this.activities, {super.key});

  @override
  Widget build(BuildContext context) {
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
            'Recent Patient Activity',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
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
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityTile(
                  patientName: activity['patientName'] ?? 'Unknown',
                  action: activity['action'] ?? '',
                  timeAgo: activity['timeAgo'] ?? '',
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.patientName,
    required this.action,
    required this.timeAgo,
  });

  final String patientName;
  final String action;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.accentWithOpacity(0.35),
          radius: 18,
          child: const Icon(
            Icons.person,
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
                patientName,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action,
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
          timeAgo,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
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