// lib/presentation/pages/patient_attachments/widgets/category_badge.dart

import 'package:flutter/material.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class CategoryBadge extends StatelessWidget {
  final String category;

  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _CategoryConfig _getConfig() {
    switch (category) {
      case 'xray':
        return _CategoryConfig(
            'X-Ray', Icons.medical_information, AppColors.info);
      case 'photo':
        return _CategoryConfig(
            'Photo', Icons.camera_alt_outlined, AppColors.success);
      case 'consent_form':
        return _CategoryConfig(
            'Consent', Icons.description_outlined, AppColors.warning);
      case 'treatment_plan':
        return _CategoryConfig(
            'Treatment', Icons.healing_outlined, AppColors.primary);
      case 'lab_report':
        return _CategoryConfig(
            'Lab Report', Icons.science_outlined, AppColors.primaryDark);
      case 'prescription':
        return _CategoryConfig(
            'Prescription', Icons.medication_outlined, AppColors.error);
      case 'referral':
        return _CategoryConfig(
            'Referral', Icons.send_outlined, AppColors.statusNoShow);
      default:
        return _CategoryConfig(
            'Other', Icons.insert_drive_file, AppColors.textMuted);
    }
  }
}

class _CategoryConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryConfig(this.label, this.icon, this.color);
}