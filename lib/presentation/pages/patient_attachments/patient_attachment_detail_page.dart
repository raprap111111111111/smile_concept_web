import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'shared/info_card.dart';
import 'shared/info_row.dart';
import '/presentation/pages/patient_attachments/patient_attachment_detail/utils/attachment_access.dart';      
import 'utils/attachment_helpers.dart';     
import '/presentation/pages/patient_attachments/patient_attachment_detail/utils/attachment_printer.dart';    
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

  // ══════════════════════════════════════════════════════════
  // App Bar
  // ══════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    // ✅ Only show print button for supported types
    final canPrint = AttachmentHelpers.isPdf(attachment.fileType) ||
        AttachmentHelpers.isImage(attachment.fileType);

    return AppBar(
      title: Text('Attachment Details', style: AppTextStyles.titleLarge),
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        // ✅ Print button
        if (canPrint)
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.textMuted),
            tooltip: 'Print',
            onPressed: () => AttachmentPrinter.print(context, ref, attachment),
          ),

        // ✅ FIXED — Open in new tab (uses token-based URL now)
        IconButton(
          icon: const Icon(Icons.open_in_new, color: AppColors.textMuted),
          tooltip: 'Open in new tab',
          onPressed: () => _openInNewTab(context, ref),
        ),

        // More menu (Download + Delete)
        PopupMenuButton<String>(
          onSelected: (val) async {
            if (val == 'download') {
              await _downloadFile(context, ref);
            } else if (val == 'delete') {
              await _confirmDelete(context, ref);
            }
          },
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download_outlined,
                      color: AppColors.textMuted, size: 18),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuDivider(),
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

  // ══════════════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════════════

  /// Opens the file in a new browser tab using a token-based URL.
  Future<void> _openInNewTab(BuildContext context, WidgetRef ref) async {
    _showLoading(context, 'Opening file…');

    try {
      final url = await AttachmentAccess.getFileUrl(ref, attachment.id);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        FileLauncher.openUrl(context, url);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _showError(context, 'Failed to open file: $e');
      }
    }
  }

  /// Downloads the file using a token-based URL.
  Future<void> _downloadFile(BuildContext context, WidgetRef ref) async {
    _showLoading(context, 'Preparing download…');

    try {
      final url = await AttachmentAccess.getDownloadUrl(ref, attachment.id);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        FileLauncher.openUrl(context, url);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _showError(context, 'Failed to download: $e');
      }
    }
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

  // ══════════════════════════════════════════════════════════
  // UI Helpers
  // ══════════════════════════════════════════════════════════

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }
}