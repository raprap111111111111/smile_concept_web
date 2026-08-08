// lib/presentation/pages/doctor_schedules/widgets/days_checkbox_list.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../constants.dart';

class DaysCheckboxList extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  const DaysCheckboxList({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  void _toggleDay(int value) {
    final newSet = Set<int>.from(selectedDays);
    if (newSet.contains(value)) {
      newSet.remove(value);
    } else {
      newSet.add(value);
    }
    onChanged(newSet);
  }

  void _toggleAll() {
    if (selectedDays.length == 7) {
      onChanged({});
    } else {
      onChanged(kDaysOfWeek.map((d) => d['value'] as int).toSet());
    }
  }

  void _toggleWeekdays() {
    onChanged({1, 2, 3, 4, 5}); // Mon-Fri
  }

  void _toggleWeekend() {
    onChanged({0, 6}); // Sun & Sat
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedDays.length == 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Days of Week',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              if (selectedDays.isNotEmpty)
                Text(
                  '${selectedDays.length} selected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),

        // ── Quick Actions ─────────────────────────────────────────────
        Wrap(
          spacing: 8,
          children: [
            _QuickActionChip(
              label: allSelected ? 'Clear All' : 'Select All',
              icon: allSelected ? Icons.close : Icons.done_all,
              onPressed: _toggleAll,
            ),
            _QuickActionChip(
              label: 'Weekdays',
              icon: Icons.work_outline,
              onPressed: _toggleWeekdays,
            ),
            _QuickActionChip(
              label: 'Weekend',
              icon: Icons.weekend_outlined,
              onPressed: _toggleWeekend,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Checkboxes ────────────────────────────────────────────────
        Container(
          // The fill lives on the Material below, not here: an opaque
          // DecoratedBox between ListTile and its Material breaks ink splashes
          // and trips a framework assertion.
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: AppColors.surface,
            child: Column(
              children: kDaysOfWeek.map((day) {
                final value = day['value'] as int;
                final label = day['label'] as String;
                final isSelected = selectedDays.contains(value);

                return CheckboxListTile(
                  title: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          isSelected ? AppColors.ink : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (_) => _toggleDay(value),
                  activeColor: AppColors.primary,
                  checkColor: AppColors.textOnPrimary,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Material's `ActionChip` picks its fill and label colour from the ambient
/// theme, which is still `ThemeData.dark()` app-wide — a dark pill with a
/// near-white label on this light card. Colours are set explicitly instead.
class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}