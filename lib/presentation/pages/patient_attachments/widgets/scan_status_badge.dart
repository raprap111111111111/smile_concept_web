// lib/presentation/pages/patient_attachments/widgets/scan_status_badge.dart

import 'package:flutter/material.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class ScanStatusBadge extends StatelessWidget {
  final String status;

  const ScanStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'processing')
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: config.color,
              ),
            )
          else
            Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _ScanConfig _getConfig() {
    switch (status) {
      case 'pending':
        return _ScanConfig(
          'Pending Scan',
          Icons.schedule_rounded,
          AppColors.warning,
        );
      case 'processing':
        return _ScanConfig(
          'Scanning...',
          Icons.sync_rounded,
          AppColors.info,
        );
      case 'completed':
        return _ScanConfig(
          'Scan Done',
          Icons.check_circle_rounded,
          AppColors.success,
        );
      case 'failed':
        return _ScanConfig(
          'Scan Failed',
          Icons.error_rounded,
          AppColors.error,
        );
      default:
        return _ScanConfig(
          'No Scan',
          Icons.remove_circle_outline_rounded,
          AppColors.textMuted,
        );
    }
  }
}

class _ScanConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _ScanConfig(this.label, this.icon, this.color);
}