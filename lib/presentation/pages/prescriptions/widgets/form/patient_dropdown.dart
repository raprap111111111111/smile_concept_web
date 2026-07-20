// lib/presentation/pages/prescriptions/widgets/form/patient_dropdown.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/patient/patient_list_provider.dart';
import '/presentation/widgets/shared/status_field.dart';

class PatientDropdown extends ConsumerWidget {
  final int? selectedPatientId;
  final ValueChanged<int?> onChanged;

  const PatientDropdown({
    super.key,
    required this.selectedPatientId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(patientListProvider);

    if (patientsState.isLoading && patientsState.patients.isEmpty) {
      return const StatusField(label: 'Loading patients...');
    }

    if (patientsState.errorMessage != null &&
        patientsState.patients.isEmpty) {
      return StatusField(
        label: 'Failed to load patients',
        isError: true,
        onRetry: () =>
            ref.read(patientListProvider.notifier).refresh(),
      );
    }

    if (patientsState.patients.isEmpty) {
      return const StatusField(label: 'No patients available');
    }

    return DropdownButtonFormField<int>(
      initialValue: selectedPatientId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Patient *',
        prefixIcon: Icon(Icons.face_outlined),
      ),
      hint: const Text('Select patient'),
      items: patientsState.patients
          .map(
            (pat) => DropdownMenuItem<int>(
              value: pat.userId,
              child: Text(
                pat.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (val) =>
          val == null ? 'Please select a patient' : null,
    );
  }
}