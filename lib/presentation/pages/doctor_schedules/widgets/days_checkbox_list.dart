// lib/presentation/pages/doctor_schedules/widgets/days_checkbox_list.dart

import 'package:flutter/material.dart';
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
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Days of Week',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (selectedDays.isNotEmpty)
                Text(
                  '${selectedDays.length} selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),

        // ── Quick Actions ─────────────────────────────────────────────
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: Text(allSelected ? 'Clear All' : 'Select All'),
              avatar: Icon(
                allSelected ? Icons.close : Icons.done_all,
                size: 16,
              ),
              onPressed: _toggleAll,
            ),
            ActionChip(
              label: const Text('Weekdays'),
              avatar: const Icon(Icons.work_outline, size: 16),
              onPressed: _toggleWeekdays,
            ),
            ActionChip(
              label: const Text('Weekend'),
              avatar: const Icon(Icons.weekend_outlined, size: 16),
              onPressed: _toggleWeekend,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Checkboxes ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: kDaysOfWeek.map((day) {
              final value = day['value'] as int;
              final label = day['label'] as String;
              final isSelected = selectedDays.contains(value);

              return CheckboxListTile(
                title: Text(label),
                value: isSelected,
                onChanged: (_) => _toggleDay(value),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}