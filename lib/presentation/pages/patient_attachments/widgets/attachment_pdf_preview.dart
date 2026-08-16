import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/config/api_config.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '/presentation/pages/patient_attachments/patient_attachment_detail/utils/attachment_printer.dart'; 
import '../utils/file_launcher.dart';

// ✅ Changed from StatelessWidget → ConsumerWidget so we can use ref
class AttachmentPdfPreview extends ConsumerWidget {
  final PatientAttachment attachment;

  const AttachmentPdfPreview({super.key, required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ApiConfig.attachmentFileUrl(attachment.id);

    return GestureDetector(
      onTap: () => FileLauncher.openUrl(context, url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('PDF Document', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              attachment.fileName,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ✅ Row of action buttons (Open + Print)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => FileLauncher.openUrl(context, url),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ NEW — Print button
                OutlinedButton.icon(
                  onPressed: () =>
                      AttachmentPrinter.print(context, ref, attachment),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}