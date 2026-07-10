// lib/presentation/pages/doctor_schedules/widgets/day_filter_row.dart

import 'package:flutter/material.dart';
import '../constants.dart';

class DayFilterRow extends StatelessWidget {
  final int? selectedDay;
  final ValueChanged<int?> onChanged;

  const DayFilterRow({
    super.key,
    required this.selectedDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('All Days'),
            selected: selectedDay == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...kDaysOfWeek.map((day) {
            final value = day['value'] as int;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(day['label'] as String),
                selected: selectedDay == value,
                onSelected: (_) =>
                    onChanged(selectedDay == value ? null : value),
              ),
            );
          }),
        ],
      ),
    );
  }
}