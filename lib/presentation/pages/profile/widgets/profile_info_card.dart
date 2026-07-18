// lib/presentation/pages/profile/widgets/profile_info_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/profile/profile_model.dart';
import 'info_card.dart';
import 'profile_theme.dart';

class ProfileInfoCard extends StatelessWidget {
  final ProfileModel profile;
  const ProfileInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = <InfoRow>[
      InfoRow(
        icon: Icons.badge_outlined,
        label: 'Full name',
        value: profile.name,
      ),
      InfoRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: profile.email,
        trailing: profile.isEmailVerified
            ? const Tooltip(
                message: 'Email verified',
                child: Icon(
                  Icons.verified,
                  color: ProfileTokens.brand,
                  size: 15,
                ),
              )
            : null,
      ),
      InfoRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: profile.phone ?? 'Not provided',
        isEmpty: profile.phone == null,
      ),
      InfoRow(
        icon: Icons.shield_outlined,
        label: 'Role',
        value: _titleCase(profile.role),
      ),
      if (profile.hasBranch)
        InfoRow(
          icon: Icons.business_outlined,
          label: 'Branch',
          value: profile.primaryBranch?.name ?? 'Not assigned',
          isEmpty: profile.primaryBranch?.name == null,
        ),
      InfoRow(
        icon: profile.isActive
            ? Icons.check_circle_outline
            : Icons.cancel_outlined,
        iconColor:
            profile.isActive ? ProfileTokens.success : ProfileTokens.neutral,
        label: 'Account status',
        value: profile.isActive ? 'Active' : 'Inactive',
      ),
      InfoRow(
        icon: Icons.calendar_today_outlined,
        label: 'Member since',
        value: profile.createdAt != null
            ? _formatDate(profile.createdAt!)
            : 'Unknown',
        isEmpty: profile.createdAt == null,
      ),
    ];

    return InfoCard(
      title: 'Account information',
      icon: Icons.person_outline,
      iconColor: ProfileTokens.brand,
      children: [
        for (var i = 0; i < rows.length; i++)
          if (i == rows.length - 1)
            // Rebuild the final row without its bottom divider.
            InfoRow(
              icon: rows[i].icon,
              iconColor: rows[i].iconColor,
              label: rows[i].label,
              value: rows[i].value,
              isEmpty: rows[i].isEmpty,
              trailing: rows[i].trailing,
              isLast: true,
            )
          else
            rows[i],
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

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
