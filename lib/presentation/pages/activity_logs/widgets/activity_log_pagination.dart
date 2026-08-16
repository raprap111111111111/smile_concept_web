import 'package:flutter/material.dart';

import '../../../../data/models/activity_log/activity_log_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ActivityLogPagination extends StatelessWidget {
  final ActivityLogListResult result;
  final ValueChanged<int> onPageChanged;

  const ActivityLogPagination({
    super.key,
    required this.result,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          Text(
            'Showing ${result.records.length} of ${result.total}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          _pageButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            enabled: result.currentPage > 1,
            onPressed: () => onPageChanged(result.currentPage - 1),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${result.currentPage} / ${result.lastPage}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _pageButton(
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            enabled: result.currentPage < result.lastPage,
            onPressed: () => onPageChanged(result.currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.background : AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
        onPressed: enabled ? onPressed : null,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}