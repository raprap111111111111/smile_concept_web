// lib/presentation/pages/prescriptions/widgets/shared/status_field.dart
import 'package:flutter/material.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_text_styles.dart';

class StatusField extends StatelessWidget {
  final String label;
  final bool isError;
  final VoidCallback? onRetry;

  const StatusField({
    super.key,
    required this.label,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          if (isError)
            const Icon(Icons.error_outline, color: AppColors.error, size: 18)
          else
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isError ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
          if (isError && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}