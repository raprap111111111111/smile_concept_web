import 'package:flutter/material.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '../utils/attachment_helpers.dart';
import 'category_badge.dart';
import 'scan_status_badge.dart';

class AttachmentFileInfoCard extends StatelessWidget {
  final PatientAttachment attachment;

  const AttachmentFileInfoCard({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
                ),
                child: Icon(
                  AttachmentHelpers.categoryIcon(attachment.category),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attachment.fileName, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      attachment.fileType.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Row(
            children: [
              CategoryBadge(category: attachment.category),
              if (attachment.isXray) ...[
                const SizedBox(width: 8),
                ScanStatusBadge(status: attachment.scanStatus),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Uploaded: ${AttachmentHelpers.formatDateTime(attachment.createdAt)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}