// lib/presentation/pages/appointments/widgets/appointment_filter_bar.dart

import 'package:flutter/material.dart';

class AppointmentFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const AppointmentFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

static const _statuses = [
  (label: 'All', value: null),
  (label: 'Pending', value: 'pending'),      // ✅ lowercase
  (label: 'Confirmed', value: 'confirmed'),  // ✅ lowercase
  (label: 'Cancelled', value: 'cancelled'),  // ✅ lowercase
  (label: 'Completed', value: 'completed'),  // ✅ Add this
];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final item = _statuses[index];
          final isSelected = selectedStatus == item.value;

          return FilterChip(
            label: Text(item.label),
            selected: isSelected,
            onSelected: (_) => onStatusChanged(item.value),
            showCheckmark: false,
            selectedColor:
                Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}