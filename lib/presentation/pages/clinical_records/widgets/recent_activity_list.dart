// lib/presentation/pages/clinical_records/widgets/recent_activity_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/clinical_records/clinical_summary_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class RecentActivityList extends StatelessWidget {
  final List<RecentActivityModel> activities;

  const RecentActivityList({super.key, required this.activities});

  IconData _iconFor(String type) {
    switch (type) {
      case 'clinical_note':
        return Icons.note_alt_outlined;
      case 'dental_chart':
        return Icons.medical_services_outlined;
      case 'lab_case':
        return Icons.science_outlined;
      case 'attachment':
        return Icons.attach_file_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'clinical_note':
        return AppColors.info;
      case 'dental_chart':
        return AppColors.primary;
      case 'lab_case':
        return AppColors.warning;
      case 'attachment':
        return AppColors.accent;
      case 'prescription':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final a = activities[index];
          final color = _colorFor(a.type);

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconFor(a.type), color: color, size: 20),
            ),
            title: Text(
              a.title,
              style: AppTextStyles.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                if (a.patientName != null) a.patientName!,
                if (a.subtitle != null) a.subtitle!,
              ].join(' • '),
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatDate(a.createdAt),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }
}