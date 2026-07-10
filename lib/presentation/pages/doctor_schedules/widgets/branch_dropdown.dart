// lib/presentation/pages/doctor_schedules/widgets/branch_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/doctor_schedule/schedule_form_providers.dart'; 
import 'dropdown_states.dart';

class BranchDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const BranchDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesListProvider);

    return branchesAsync.when(
      loading: () => const DropdownSkeleton(label: 'Loading branches...'),
      error: (e, _) => const DropdownError(message: 'Failed to load branches'),
      data: (branches) {
        return DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Branch',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          hint: const Text('Select a branch'),
          items: branches
              .map((br) => DropdownMenuItem<int>(
                    value: br.id,
                    child: Text(
                      br.displayLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select a branch' : null,
        );
      },
    );
  }
}