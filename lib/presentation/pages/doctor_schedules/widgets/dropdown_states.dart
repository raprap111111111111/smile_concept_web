import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

// Example skeleton widget
class DropdownSkeleton extends StatelessWidget {
  final String label;
  const DropdownSkeleton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: false,
      style: AppTextStyles.inputHint,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.inputHint,
        prefixIcon: const Icon(
          Icons.hourglass_empty,
          color: AppColors.textMuted,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// Example error widget
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          enabled: false,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Error',
            labelStyle: const TextStyle(color: AppColors.error),
            prefixIcon: const Icon(
              Icons.error_outline,
              color: AppColors.error,
            ),
            errorText: message,
            border: const OutlineInputBorder(),
          ),
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Text(
              detail!,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ),
      ],
    );
  }
}
