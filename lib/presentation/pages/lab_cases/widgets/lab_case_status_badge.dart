// lib/presentation/pages/lab_cases/widgets/lab_case_status_badge.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'package:smile_concept_web/data/models/lab_case/lab_case_constants.dart';

class LabCaseStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const LabCaseStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            LabCaseStatus.label(status),
            style: (compact
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(color: config.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig(String status) {
    return switch (status) {
      'sent' => _BadgeConfig(
          background: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
          dot: const Color(0xFF3B82F6),
          text: const Color(0xFF1D4ED8),
        ),
      'in_progress' => _BadgeConfig(
          background: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          dot: const Color(0xFFF59E0B),
          text: const Color(0xFF92400E),
        ),
      'received' => _BadgeConfig(
          background: const Color(0xFFECFEFF),
          border: const Color(0xFFA5F3FC),
          dot: AppColors.primary,
          text: const Color(0xFF0E7490),
        ),
      'fitted' => _BadgeConfig(
          background: const Color(0xFFF0FDF4),
          border: const Color(0xFFBBF7D0),
          dot: AppColors.success,
          text: const Color(0xFF166534),
        ),
      'rejected' => _BadgeConfig(
          background: const Color(0xFFFFF1F2),
          border: const Color(0xFFFFCDD2),
          dot: AppColors.error,
          text: const Color(0xFF9B1C1C),
        ),
      _ => _BadgeConfig(
          background: AppColors.surface,
          border: AppColors.border,
          dot: AppColors.textSecondary,
          text: AppColors.textSecondary,
        ),
    };
  }
}

class _BadgeConfig {
  final Color background;
  final Color border;
  final Color dot;
  final Color text;

  const _BadgeConfig({
    required this.background,
    required this.border,
    required this.dot,
    required this.text,
  });
}