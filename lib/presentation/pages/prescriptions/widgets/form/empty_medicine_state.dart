import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../../theme/app_text_styles.dart';

class EmptyMedicineState extends StatelessWidget {
  final VoidCallback onAdd;

  const EmptyMedicineState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          const Text(
            'No medicines added yet',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Click "Add Medicine" to begin',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Medicine'),
          ),
        ],
      ),
    );
  }
}