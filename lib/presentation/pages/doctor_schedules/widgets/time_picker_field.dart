// lib/presentation/pages/doctor_schedules/widgets/time_picker_field.dart

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class TimePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  const TimePickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay initial = TimeOfDay.now();
    final existing = controller.text;
    if (existing.length >= 5) {
      final parts = existing.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      // The dialog is pushed on the root navigator, so it is pinned light here
      // the same way the form page pins itself — otherwise the clock face
      // inherits the app's dark theme and clashes with the light form.
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.background,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickTime(context),
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        hintText: 'HH:mm:ss',
      ),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}