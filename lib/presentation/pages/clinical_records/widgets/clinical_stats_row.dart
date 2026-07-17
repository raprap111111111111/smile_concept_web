// lib/presentation/pages/clinical_records/widgets/clinical_stats_row.dart

import 'package:flutter/material.dart';
import '../../../../data/models/clinical_records/clinical_summary_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ClinicalStatsRow extends StatelessWidget {
  final ClinicalStatsModel stats;

  const ClinicalStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 2
                : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: 2.5,
          crossAxisSpacing: AppDimensions.paddingSmall,
          mainAxisSpacing: AppDimensions.paddingSmall,
          children: [
            _StatCard(
              label: 'Clinical Notes',
              value: stats.totalClinicalNotes.toString(),
              subtext: '${stats.lockedNotes} finalized',
              icon: Icons.note_alt_outlined,
              color: AppColors.info,
            ),
            _StatCard(
              label: 'Dental Charts',
              value: stats.totalDentalCharts.toString(),
              icon: Icons.medical_services_outlined,
              color: AppColors.primary,
            ),
            _StatCard(
              label: 'Lab Cases',
              value: stats.totalLabCases.toString(),
              subtext: '${stats.pendingLabCases} pending',
              icon: Icons.science_outlined,
              color: AppColors.warning,
            ),
            _StatCard(
              label: 'Attachments',
              value: stats.totalAttachments.toString(),
              icon: Icons.attach_file_outlined,
              color: AppColors.accent,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtext,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtext != null)
                  Text(
                    subtext!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}