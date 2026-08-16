import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
class DoctorInfoSection extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorInfoSection({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final user = doctor['user'] as Map? ?? {};
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '-';
    final bio = doctor['bio']?.toString();
    final experience = doctor['years_of_experience']?.toString();

    return _Section(
      title: 'Contact Information',
      icon: Icons.contact_page_outlined,
      children: [
        _InfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: email,
        ),
        _InfoTile(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: phone,
        ),
        if (experience != null && experience.isNotEmpty)
          _InfoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Experience',
            value: '$experience years',
          ),
        if (bio != null && bio.isNotEmpty)
          _InfoTile(
            icon: Icons.description_outlined,
            label: 'Bio',
            value: bio,
            isLast: true,
          ),
      ],
    );
  }
}

// ── Section wrapper ──
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

// ── Info tile ──
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}