// lib/presentation/pages/patient_attachments/widgets/attachment_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/permissions/app_permissions.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/providers/auth/auth_provider.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'category_badge.dart';
import 'scan_status_badge.dart';

class AttachmentCard extends ConsumerWidget {
  final PatientAttachment attachment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AttachmentCard({
    super.key,
    required this.attachment,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final currentUserId = auth.user?.id;

    // ✅ Permission checks
    final canViewAny = auth.hasPermission(Perm.attachmentViewAny);
    final canDelete = auth.hasPermission(Perm.attachmentDelete);

    final isMyUpload = attachment.isOwnedBy(currentUserId);

    // Can delete IF: viewAny (admin) OR (has delete + owns it)
    final canShowDelete = canViewAny || (canDelete && isMyUpload);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(
            color: isMyUpload
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
            width: isMyUpload ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ TOP ROW ═══
            Row(
              children: [
                _buildFileIcon(),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File name + "You" badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              attachment.fileName,
                              style: AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMyUpload) ...[
                            const SizedBox(width: 6),
                            _buildYouBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Patient name
                      Text(
                        attachment.patientName ?? 'Unknown Patient',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ✅ Always show uploader when viewAny
                      // (helps distinguish between uploaders in shared folder)
                      if (canViewAny && attachment.uploaderName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Uploaded by ${attachment.uploaderName}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (canShowDelete)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'delete') onDelete();
                    },
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: AppColors.error, size: 18),
                            SizedBox(width: 8),
                            Text('Delete',
                                style:
                                    TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingSmall),

            // ═══ BADGES ROW ═══
            Row(
              children: [
                CategoryBadge(category: attachment.category),
                const SizedBox(width: 8),
                if (attachment.isXray)
                  ScanStatusBadge(status: attachment.scanStatus),
              ],
            ),

            // ═══ CONDITIONS PREVIEW ═══
            if (attachment.isScanCompleted && attachment.hasConditions) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${attachment.detectedConditions.length} condition(s) detected',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      '${attachment.scanConfidence?.toStringAsFixed(0)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ═══ NOTES ═══
            if (attachment.notes != null && attachment.notes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingXS),
              Text(
                attachment.notes!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ═══ DATE ═══
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              _formatDate(attachment.createdAt),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        'You',
        style: TextStyle(
          fontSize: 9,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData icon;
    Color color;

    switch (attachment.category) {
      case 'xray':
        icon = Icons.medical_information;
        color = AppColors.info;
        break;
      case 'photo':
        icon = Icons.camera_alt_outlined;
        color = AppColors.success;
        break;
      case 'consent_form':
        icon = Icons.description_outlined;
        color = AppColors.warning;
        break;
      case 'lab_report':
        icon = Icons.science_outlined;
        color = AppColors.primaryDark;
        break;
      case 'prescription':
        icon = Icons.medication_outlined;
        color = AppColors.error;
        break;
      default:
        icon = Icons.insert_drive_file_outlined;
        color = AppColors.textMuted;
    }

    return Container(
      width: AppDimensions.iconBadgeSize,
      height: AppDimensions.iconBadgeSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Icon(icon, color: color, size: AppDimensions.iconSize),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}