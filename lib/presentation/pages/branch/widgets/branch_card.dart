import 'package:flutter/material.dart';

import '../../../../data/models/branch/branch_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BranchCard({
    super.key,
    required this.branch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppDimensions.paddingMedium),
          if (branch.fullAddress.isNotEmpty)
            _infoRow(Icons.location_on_outlined, branch.fullAddress),
          if (branch.phone != null && branch.phone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.phone_outlined, branch.phone!),
          ],
          if (branch.email != null && branch.email!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.email_outlined, branch.email!),
          ],
          const SizedBox(height: AppDimensions.paddingSmall),
          Row(
            children: [
              Expanded(
                child: _statChip(
                  Icons.people,
                  branch.staffCount.toString(),
                  'Staff',
                  AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              Expanded(
                child: _statChip(
                  Icons.event,
                  branch.appointmentsCount.toString(),
                  'Appointments',
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: AppDimensions.iconSizeSmall,
                  ),
                  label: Text(
                    'Edit',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              Material(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                child: InkWell(
                  onTap: onDelete,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: AppDimensions.iconSizeSmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isActive = branch.isActive;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            gradient: isActive
                ? AppColors.primaryGradient
                : const LinearGradient(
                    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                  ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            color: Colors.white,
            size: AppDimensions.iconSizeMedium,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch.name,
                style: AppTextStyles.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              if (branch.branchCode != null && branch.branchCode!.isNotEmpty)
                Text(
                  '#${branch.branchCode}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXS,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: AppTextStyles.labelSmall.copyWith(
              color: isActive ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconSizeSmall,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconSizeSmall, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}