import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

// ══════════════════════════════════════════════════════════════════════════
// Loading
// ══════════════════════════════════════════════════════════════════════════
class ActivityLogLoadingState extends StatelessWidget {
  const ActivityLogLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(
            'Loading activity logs…',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Error
// ══════════════════════════════════════════════════════════════════════════
class ActivityLogErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ActivityLogErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text('Failed to load activity logs',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Empty
// ══════════════════════════════════════════════════════════════════════════
class ActivityLogEmptyState extends StatelessWidget {
  const ActivityLogEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 48,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text('No activity logs found', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Try adjusting the filters or search.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}