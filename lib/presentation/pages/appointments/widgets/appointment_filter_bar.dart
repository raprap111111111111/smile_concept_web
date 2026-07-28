// lib/presentation/pages/appointments/widgets/appointment_filter_bar.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class AppointmentFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const AppointmentFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const _statuses = <({
    String label,
    String? value,
    IconData? icon,
    Color? color,
  })>[
    (label: 'All', value: null, icon: null, color: null),
    (
      label: 'Pending',
      value: 'pending',
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
    ),
    (
      label: 'Confirmed',
      value: 'confirmed',
      icon: Icons.check_circle_rounded,
      color: AppColors.info,
    ),
    (
      label: 'Completed',
      value: 'completed',
      icon: Icons.done_all_rounded,
      color: AppColors.success,
    ),
    (
      label: 'Cancelled',
      value: 'cancelled',
      icon: Icons.cancel_rounded,
      color: AppColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimensions.paddingXS),
          itemCount: _statuses.length,
          itemBuilder: (context, index) {
            final item = _statuses[index];
            final isSelected = selectedStatus == item.value;
            return _StatusChip(
              label: item.label,
              icon: item.icon,
              accentColor: item.color,
              isSelected: isSelected,
              onTap: () => onStatusChanged(item.value),
            );
          },
        ),
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          // ✅ Soft tinted background when selected instead of bright fill
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: 14,
                color: activeColor,
              ),
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: activeColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? activeColor
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}