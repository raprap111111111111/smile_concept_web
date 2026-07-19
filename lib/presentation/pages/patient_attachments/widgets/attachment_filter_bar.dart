// lib/presentation/pages/patient_attachments/widgets/attachment_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class AttachmentFilterBar extends ConsumerWidget {
  const AttachmentFilterBar({super.key});

  static const _categories = [
    ('All', null),
    ('X-Rays', 'xray'),
    ('Photos', 'photo'),
    ('Consent', 'consent_form'),
    ('Lab Reports', 'lab_report'),
    ('Prescriptions', 'prescription'),
    ('Other', 'other'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Only rebuild when categoryFilter changes
    final categoryFilter = ref.watch(
      patientAttachmentProvider.select((s) => s.categoryFilter),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingSmall,
        horizontal: AppDimensions.paddingMedium,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final isActive = categoryFilter == cat.$2;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.$1),
                selected: isActive,
                onSelected: (_) => ref
                    .read(patientAttachmentProvider.notifier)
                    .setCategoryFilter(isActive ? null : cat.$2),
                backgroundColor: AppColors.surface,
                selectedColor:
                    AppColors.primary.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTextStyles.labelSmall.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isActive
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
                side: BorderSide(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}