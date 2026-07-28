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

    final canViewAny = auth.hasPermission(Perm.attachmentViewAny);
    final canDelete = auth.hasPermission(Perm.attachmentDelete);
    final isMyUpload = attachment.isOwnedBy(currentUserId);
    final canShowDelete = canViewAny || (canDelete && isMyUpload);

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(
              color: isMyUpload
                  ? AppColors.primaryWithOpacity(0.3)
                  : AppColors.border,
              width: isMyUpload ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ HEADER ROW ═══
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FileIcon(category: attachment.category),
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
                              const _YouBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Patient name
                        Text(
                          attachment.patientName ?? 'Unknown Patient',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Uploader hint (shared folder view)
                        if (canViewAny && attachment.uploaderName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Uploaded by ${attachment.uploaderName}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w400,
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
                  if (canShowDelete) _AttachmentMenu(onDelete: onDelete),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingSmall),

              // ═══ BADGES ROW ═══
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  CategoryBadge(category: attachment.category),
                  if (attachment.isXray)
                    ScanStatusBadge(status: attachment.scanStatus),
                ],
              ),

              // ═══ CONDITIONS BANNER ═══
              if (attachment.isScanCompleted && attachment.hasConditions) ...[
                const SizedBox(height: AppDimensions.paddingSmall),
                _ConditionsBanner(
                  count: attachment.detectedConditions.length,
                  confidence: attachment.scanConfidence,
                ),
              ],

              // ═══ NOTES ═══
              if (attachment.notes != null &&
                  attachment.notes!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingXS),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusSmall),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    attachment.notes!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // ═══ FOOTER: DATE ═══
              const SizedBox(height: AppDimensions.paddingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(attachment.createdAt),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

// ─── File Icon ────────────────────────────────────────────────────────────────

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(category);

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

  (IconData, Color) _iconFor(String category) {
    switch (category) {
      case 'xray':
        return (Icons.medical_information_rounded, AppColors.info);
      case 'photo':
        return (Icons.camera_alt_rounded, AppColors.success);
      case 'consent_form':
        return (Icons.description_rounded, AppColors.warning);
      case 'lab_report':
        return (Icons.science_rounded, AppColors.primaryDark);
      case 'prescription':
        return (Icons.medication_rounded, AppColors.error);
      default:
        return (Icons.insert_drive_file_rounded, AppColors.textMuted);
    }
  }
}

// ─── "You" Badge ──────────────────────────────────────────────────────────────

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.primaryWithOpacity(0.3)),
      ),
      child: const Text(
        'YOU',
        style: TextStyle(
          fontSize: 9,
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Attachment Menu (Delete Popup) ───────────────────────────────────────────

class _AttachmentMenu extends StatelessWidget {
  const _AttachmentMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'delete') onDelete();
      },
      tooltip: 'More options',
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.textSecondary,
          size: AppDimensions.iconSizeSmall,
        ),
      ),
      // ✅ Force light theme for popup (fixes the black popup issue)
      color: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        side: const BorderSide(color: AppColors.border),
      ),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSmall,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusSmall,
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              Text(
                'Delete',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Conditions Banner ────────────────────────────────────────────────────────

class _ConditionsBanner extends StatelessWidget {
  const _ConditionsBanner({
    required this.count,
    required this.confidence,
  });

  final int count;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 16,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Text(
              '$count condition(s) detected',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          if (confidence != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
              ),
              child: Text(
                '${confidence!.toStringAsFixed(0)}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}