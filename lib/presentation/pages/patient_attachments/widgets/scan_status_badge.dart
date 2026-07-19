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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
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
            Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.w700,
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
            'Pending Scan', Icons.schedule, AppColors.statusPending);
      case 'processing':
        return _ScanConfig(
            'Scanning...', Icons.sync, AppColors.info);
      case 'completed':
        return _ScanConfig(
            'Scan Done', Icons.check_circle_outline, AppColors.success);
      case 'failed':
        return _ScanConfig(
            'Scan Failed', Icons.error_outline, AppColors.error);
      default:
        return _ScanConfig(
            'No Scan', Icons.remove_circle_outline, AppColors.textMuted);
    }
  }
}

class _ScanConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _ScanConfig(this.label, this.icon, this.color);
}