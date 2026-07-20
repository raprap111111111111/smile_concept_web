// lib/presentation/pages/prescriptions/widgets/form/medicine_item_card.dart
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../../theme/app_text_styles.dart';
import 'medicine_item_form.dart';

class MedicineItemCard extends StatelessWidget {
  final MedicineItemForm item;
  final int index;
  final VoidCallback? onRemove;

  const MedicineItemCard({
    super.key,
    required this.item,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(color: AppColors.line, height: 1),
          _buildFields(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: Row(
        children: [
          _buildNumberBadge(),
          const SizedBox(width: 10),
          Text(
            'Medicine ${index + 1}',
            style: AppTextStyles.labelLarge,
          ),
          const Spacer(),
          if (onRemove != null) _buildRemoveButton(),
        ],
      ),
    );
  }

  Widget _buildNumberBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppColors.error,
            size: 16,
          ),
        ),
      ),
    );
  }

  // ── Fields ────────────────────────────────────────────
  Widget _buildFields() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          _buildMedicineNameField(),
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildDosageRow(),
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildDurationField(),
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildInstructionsField(),
        ],
      ),
    );
  }

  Widget _buildMedicineNameField() {
    return _StyledTextField(
      controller: item.medicineController,
      label: 'Medicine Name *',
      hint: 'e.g., Amoxicillin',
      prefixIcon: Icons.medication_outlined,
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDosageRow() {
    return Row(
      children: [
        Expanded(
          child: _StyledTextField(
            controller: item.dosageController,
            label: 'Dosage *',
            hint: 'e.g., 500mg',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        Expanded(
          child: _StyledTextField(
            controller: item.frequencyController,
            label: 'Frequency *',
            hint: 'e.g., 3x daily',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return _StyledTextField(
      controller: item.durationController,
      label: 'Duration (days) *',
      hint: 'e.g., 7',
      prefixIcon: Icons.calendar_today_outlined,
      keyboardType: TextInputType.number,
      validator: _validateDuration,
    );
  }

  Widget _buildInstructionsField() {
    return _StyledTextField(
      controller: item.instructionsController,
      label: 'Instructions (Optional)',
      hint: 'e.g., Take after meal',
      maxLines: 2,
    );
  }

  String? _validateDuration(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (int.tryParse(v.trim()) == null) return 'Must be a number';
    if (int.parse(v.trim()) < 1) return 'Must be at least 1';
    return null;
  }
}

// ── Private styled text field ─────────────────────────────
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        fillColor: AppColors.background,
        filled: true,
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 2),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}