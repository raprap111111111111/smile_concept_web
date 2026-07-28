// lib/presentation/pages/patient_attachments/widgets/patient_folder_card.dart

import 'package:flutter/material.dart';
import '/core/config/api_config.dart';
import '/data/models/patient_attachment/patient_with_attachments.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class PatientFolderCard extends StatelessWidget {
  final PatientWithAttachments patient;
  final VoidCallback onTap;

  const PatientFolderCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // ─── Avatar ────────────────────────────────
              _PatientAvatar(
                photoUrl: patient.profilePhoto,
                initials: patient.initials,
              ),
              const SizedBox(width: AppDimensions.paddingMedium),

              // ─── Content ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.name,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (patient.hasPendingScans)
                          _PendingBadge(count: patient.pendingScans),
                      ],
                    ),
                    if (patient.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        patient.email!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.paddingXS),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _StatChip(
                          icon: Icons.attach_file_rounded,
                          label: '${patient.attachmentCount} files',
                          color: AppColors.primary,
                        ),
                        if (patient.xrayCount > 0)
                          _StatChip(
                            icon: Icons.medical_information_rounded,
                            label: '${patient.xrayCount} X-rays',
                            color: AppColors.info,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.paddingXS),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: AppDimensions.iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _PatientAvatar extends StatelessWidget {
  const _PatientAvatar({required this.photoUrl, required this.initials});

  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              ApiConfig.storageUrl(photoUrl!),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _buildInitials();
              },
              errorBuilder: (_, __, ___) => _buildInitials(),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─── Pending Badge ────────────────────────────────────────────────────────────

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.warning,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}