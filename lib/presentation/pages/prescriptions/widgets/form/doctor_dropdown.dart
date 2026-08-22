// lib/presentation/pages/prescriptions/widgets/form/doctor_dropdown.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/doctor/doctor_list_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
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
          initialValue: widget.selectedDoctorId,
          isExpanded: true,
          // ✅ Light dropdown menu (fixes black background)
          dropdownColor: AppColors.surface,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          decoration: InputDecoration(
            labelText: 'Doctor *',
            hintText: 'Select doctor',
            prefixIcon: const Icon(Icons.person_outlined),
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          hint: Text(
            'Select doctor',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textTertiary),
          ),
          items: doctors
              .map(
                (doc) => DropdownMenuItem<int>(
                  value: doc.id,
                  child: Text(
                    doc.displayLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
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