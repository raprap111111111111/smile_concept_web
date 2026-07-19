import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/config/api_config.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'shared/info_card.dart';
import 'shared/info_row.dart';
import 'utils/file_launcher.dart';
import 'widgets/attachment_conditions_card.dart';
import 'widgets/attachment_file_info_card.dart';
import 'widgets/attachment_preview.dart';
import 'widgets/attachment_scan_results_card.dart';

class PatientAttachmentDetailPage extends ConsumerWidget {
  final PatientAttachment attachment;

  const PatientAttachmentDetailPage({super.key, required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context, ref),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview (image/pdf/generic)
            AttachmentPreview(attachment: attachment),
            const SizedBox(height: AppDimensions.paddingMedium),

            // File info
            AttachmentFileInfoCard(attachment: attachment),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Patient info
            InfoCard(
              title: 'Patient',
              icon: Icons.person_outline,
              children: [
                InfoRow(label: 'Name', value: attachment.patientName ?? 'N/A'),
                InfoRow(label: 'Patient ID', value: '#${attachment.userId}'),
                if (attachment.appointmentId != null)
                  InfoRow(
                    label: 'Appointment',
                    value: '#${attachment.appointmentId}',
                  ),
              ],
            ),

            // Notes
            if (attachment.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              InfoCard(
                title: 'Notes',
                icon: Icons.notes_outlined,
                children: [
                  Text(attachment.notes!, style: AppTextStyles.bodyMedium),
                ],
              ),
            ],

            // Scan Results
            if (attachment.isXray) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              AttachmentScanResultsCard(attachment: attachment),
            ],

            // Detected Conditions
            if (attachment.isScanCompleted && attachment.hasConditions) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              AttachmentConditionsCard(attachment: attachment),
            ],

            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text('Attachment Details', style: AppTextStyles.titleLarge),
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.open_in_new, color: AppColors.textMuted),
          tooltip: 'Open in new tab',
          onPressed: () => FileLauncher.openUrl(
            context,
            ApiConfig.attachmentFileUrl(attachment.id),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'delete') _confirmDelete(context, ref);
          },
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: Text('Delete Attachment', style: AppTextStyles.titleMedium),
        content: Text(
          'Are you sure you want to delete "${attachment.fileName}"?\n'
          'This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(patientAttachmentProvider.notifier)
        .delete(attachment.id);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attachment deleted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
      );
    }
  }
}