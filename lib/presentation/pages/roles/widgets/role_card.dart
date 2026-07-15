import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final VoidCallback onPermissions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RoleCard({
    super.key,
    required this.role,
    required this.onPermissions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = role['name']?.toString() ?? '';
    final description = role['description']?.toString();
    final usersCount = role['users_count'] ?? 0;
    final permissionsCount = role['permissions_count'] ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name: name, description: description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statChip(
                      icon: Icons.people_alt_outlined,
                      value: usersCount.toString(),
                      label: 'Users',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statChip(
                      icon: Icons.key_outlined,
                      value: permissionsCount.toString(),
                      label: 'Perms',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: _permissionsButton()),
                  const SizedBox(width: 8),
                  _iconAction(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit role',
                    color: AppColors.primaryDark,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _iconAction(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete role',
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String name,
    required String? description,
  }) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.accentWithOpacity(0.22),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primaryDark,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description?.isNotEmpty == true
                    ? description!
                    : 'No description',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionsButton() {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: InkWell(
        onTap: onPermissions,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security_outlined, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Permissions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}