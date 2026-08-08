// lib/presentation/pages/inventory/widgets/dropdown_states.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

// ── Loading Skeleton ──────────────────────────────────────────
class DropdownSkeleton extends StatelessWidget {
  final String label;

  const DropdownSkeleton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────
class DropdownError extends StatelessWidget {
  final String message;

  /// Why the load failed — a 403, a dead API port, a parse error. Without it
  /// `message` alone ("Failed to load branches") names the symptom and hides
  /// every cause behind one string.
  final String? detail;

  final VoidCallback? onRetry;

  const DropdownError({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error,
              size: AppDimensions.iconSizeMedium),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}