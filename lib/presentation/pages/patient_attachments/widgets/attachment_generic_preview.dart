import 'package:flutter/material.dart';
import '/core/config/api_config.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '../utils/file_launcher.dart';

class AttachmentGenericPreview extends StatelessWidget {
  final PatientAttachment attachment;

  const AttachmentGenericPreview({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.attachmentDownloadUrl(attachment.id);

    return GestureDetector(
      onTap: () => FileLauncher.openUrl(context, url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insert_drive_file_outlined,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(attachment.fileType.toUpperCase(), style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(attachment.fileName, style: AppTextStyles.bodySmall,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppDimensions.paddingMedium),
            OutlinedButton.icon(
              onPressed: () => FileLauncher.openUrl(context, url),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download / Open'),
            ),
          ],
        ),
      ),
    );
  }
}