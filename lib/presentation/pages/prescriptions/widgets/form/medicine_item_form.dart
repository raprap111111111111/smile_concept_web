// lib/presentation/pages/prescriptions/widgets/form/medicine_item_form.dart
import 'package:flutter/material.dart';

class MedicineItemForm {
  final TextEditingController medicineController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;
  final TextEditingController instructionsController;

  MedicineItemForm()
      : medicineController = TextEditingController(),
        dosageController = TextEditingController(),
        frequencyController = TextEditingController(),
        durationController = TextEditingController(),
        instructionsController = TextEditingController();

  void dispose() {
    medicineController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }

  Map<String, dynamic> toPayload() {
    return {
      'medicine_name': medicineController.text.trim(),
      'dosage': dosageController.text.trim(),
      'frequency': frequencyController.text.trim(),
      'duration_days': int.tryParse(durationController.text.trim()) ?? 0,
      'instructions': instructionsController.text.trim().isEmpty
          ? null
          : instructionsController.text.trim(),
    };
  }
}