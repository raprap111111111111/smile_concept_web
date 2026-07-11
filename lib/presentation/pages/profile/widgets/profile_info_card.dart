// lib/presentation/pages/profile/widgets/profile_info_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/profile/profile_model.dart';
import '../../../theme/app_colors.dart';
import 'info_card.dart';

class ProfileInfoCard extends StatelessWidget {
  final ProfileModel profile;
  const ProfileInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Account Information',
      icon: Icons.person_outline,
      iconColor: AppColors.primary,
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Full Name',
          value: profile.name,
        ),
        _InfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email,
          trailing: profile.isEmailVerified
              ? const Icon(Icons.verified,
                  color: Colors.blueAccent, size: 16)
              : null,
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile.phone ?? 'Not provided',
          isEmpty: profile.phone == null,
        ),
        _InfoRow(
          icon: Icons.shield_outlined,
          label: 'Role',
          value: profile.role,
        ),
        if (profile.hasBranch)
          _InfoRow(
            icon: Icons.business_outlined,
            label: 'Branch',
            value: profile.primaryBranch?.name ?? '—',
          ),
        _InfoRow(
          icon: Icons.circle,
          iconColor: profile.isActive ? Colors.green : Colors.grey,
          label: 'Status',
          value: profile.isActive ? 'Active' : 'Inactive',
        ),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Member Since',
          value: profile.createdAt != null
              ? _formatDate(profile.createdAt!)
              : '—',
          isLast: true,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widget
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final bool isEmpty;
  final bool isLast;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.isLast = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.white).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isEmpty
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}