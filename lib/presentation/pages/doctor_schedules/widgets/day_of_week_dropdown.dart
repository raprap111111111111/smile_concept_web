// lib/presentation/pages/doctor_schedules/widgets/day_of_week_dropdown.dart

import 'package:flutter/material.dart';
import '../constants.dart';

class DayOfWeekDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const DayOfWeekDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Day of Week',
        prefixIcon: Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(),
      ),
      items: kDaysOfWeek
          .map(
            (day) => DropdownMenuItem<int>(
              value: day['value'] as int,
              child: Text(day['label'] as String),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select a day' : null,
    );
  }
}