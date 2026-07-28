// lib/presentation/pages/users/widgets/user_card.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? '-';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '-';
    final isActive = _asBool(user['is_active']);
    final roles = _extractRoleNames(user['roles']);
    final roleColor = _colorForRole(roles.isNotEmpty ? roles.first : '');
    final initials = _initials(name);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar + name + status ───────
          Row(
            children: [
              _UserAvatar(initials: initials, color: roleColor),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusDot(isActive: isActive),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),

          // ── Role chips ─────────────────────────────
          if (roles.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: roles.map((role) {
                return _RoleChip(label: role, color: roleColor);
              }).toList(),
            ),

          const SizedBox(height: AppDimensions.paddingSmall),

          // ── Phone ──────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.phone_rounded,
                color: AppColors.textTertiary,
                size: AppDimensions.iconSizeSmall,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  phone,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppDimensions.paddingSmall),

          // ── Actions ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: AppDimensions.iconSizeSmall,
                  ),
                  label: Text(
                    'Edit',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingXS,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              _DeleteButton(onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _extractRoleNames(dynamic roles) {
    if (roles is! List) return [];
    return roles.map<String>((role) {
      if (role is Map && role['name'] != null) return role['name'].toString();
      return role.toString();
    }).toList();
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Color _colorForRole(dynamic role) {
    final value = role.toString().toLowerCase();
    if (value.contains('admin')) return const Color(0xFF7C3AED);
    if (value.contains('dentist') || value.contains('doctor')) {
      return AppColors.primary;
    }
    if (value.contains('receptionist')) return AppColors.success;
    if (value.contains('manager')) return AppColors.warning;
    return AppColors.textSecondary;
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelLarge.copyWith(color: color),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: AppTextStyles.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Delete user',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.15),
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: AppDimensions.iconSizeSmall,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}