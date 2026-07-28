// lib/presentation/pages/doctor_schedules/widgets/day_filter_row.dart

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../constants.dart';

class DayFilterRow extends StatelessWidget {
  final int? selectedDay;
  final ValueChanged<int?> onChanged;

  const DayFilterRow({
    super.key,
    required this.selectedDay,
    required this.onChanged,
  });

  /// Match the day color from ScheduleCard
  Color _getDayColor(int? dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return const Color(0xFFEF4444); // red
      case 1:
        return AppColors.primary;
      case 2:
        return const Color(0xFF8B5CF6); // purple
      case 3:
        return const Color(0xFF10B981); // emerald
      case 4:
        return const Color(0xFFF59E0B); // amber
      case 5:
        return const Color(0xFF3B82F6); // blue
      case 6:
        return const Color(0xFFEC4899); // pink
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          // ── "All Days" Pill ──────────────────────────
          _DayChip(
            label: 'All Days',
            isSelected: selectedDay == null,
            color: AppColors.primary,
            icon: Icons.calendar_view_week_rounded,
            onTap: () => onChanged(null),
          ),

          const SizedBox(width: 8),

          // ── Divider ──────────────────────────────────
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: AppColors.border,
          ),

          const SizedBox(width: 8),

          // ── Day Pills ────────────────────────────────
          ...kDaysOfWeek.map((day) {
            final value = day['value'] as int;
            final label = day['label'] as String;
            final isSelected = selectedDay == value;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _DayChip(
                label: label,
                isSelected: isSelected,
                color: _getDayColor(value),
                onTap: () => onChanged(isSelected ? null : value),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CUSTOM DAY CHIP
// ─────────────────────────────────────────────────────────
class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 12 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}