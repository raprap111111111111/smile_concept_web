// lib/presentation/pages/prescriptions/widgets/form/doctor_dropdown.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/doctor/doctor_list_provider.dart';
import '/presentation/widgets/shared/status_field.dart';


class DoctorDropdown extends ConsumerStatefulWidget {
  final int? selectedDoctorId;
  final ValueChanged<int?> onChanged;

  const DoctorDropdown({
    super.key,
    required this.selectedDoctorId,
    required this.onChanged,
  });

  @override
  ConsumerState<DoctorDropdown> createState() => _DoctorDropdownState();
}

class _DoctorDropdownState extends ConsumerState<DoctorDropdown> {
  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorSimpleListProvider);

    return doctorsAsync.when(
      loading: () => const StatusField(label: 'Loading doctors...'),
      error: (e, _) => StatusField(
        label: 'Failed to load doctors',
        isError: true,
        onRetry: () => ref.invalidate(doctorSimpleListProvider),
      ),
      data: (doctors) {
        if (doctors.isEmpty) {
          return const StatusField(label: 'No doctors available');
        }

        return DropdownButtonFormField<int>(
          // Use initialValue via key-based rebuild instead of deprecated value
          initialValue: widget.selectedDoctorId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Doctor *',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          hint: const Text('Select doctor'),
          items: doctors
              .map(
                (doc) => DropdownMenuItem<int>(
                  value: doc.id,
                  child: Text(
                    doc.displayLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: widget.onChanged,
          validator: (val) =>
              val == null ? 'Please select a doctor' : null,
        );
      },
    );
  }
}