// lib/presentation/pages/doctor_schedules/widgets/doctor_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/doctor_schedule/schedule_form_providers.dart';
import 'dropdown_states.dart';

class DoctorDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const DoctorDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsListProvider);

    return doctorsAsync.when(
      loading: () => const DropdownSkeleton(label: 'Loading doctors...'),
      error: (e, _) => const DropdownError(message: 'Failed to load doctors'),
      data: (doctors) {
        return DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Doctor',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          hint: const Text('Select a doctor'),
          items: doctors
              .map((doc) => DropdownMenuItem<int>(
                    value: doc.id,
                    child: Text(
                      doc.displayLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select a doctor' : null,
        );
      },
    );
  }
}