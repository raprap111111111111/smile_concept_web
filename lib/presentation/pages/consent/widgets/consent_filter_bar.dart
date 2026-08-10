import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

class ConsentFilterBar extends StatelessWidget {
  final String? selectedStatus;             
  final ValueChanged<String?> onStatusChanged;

  const ConsentFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label:    'All',
            icon:     Icons.check_rounded,
            color:    AppColors.primary,
            selected: selectedStatus == null,
            onTap:    () => onStatusChanged(null),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          _FilterChip(
            label:    'Valid',
            icon:     Icons.verified_rounded,
            color:    AppColors.success,
            selected: selectedStatus == 'valid',
            onTap:    () => onStatusChanged('valid'),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          _FilterChip(
            label:    'Voided',
            icon:     Icons.cancel_rounded,
            color:    AppColors.error,
            selected: selectedStatus == 'voided',
            onTap:    () => onStatusChanged('voided'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final bool         selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}