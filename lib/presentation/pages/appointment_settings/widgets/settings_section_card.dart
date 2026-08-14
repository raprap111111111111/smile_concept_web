import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// White card with an icon + title header, matching the doctor-schedule
/// form's _FormCard look. [notEnforced] adds a visible amber badge for
/// settings that are stored but not yet enforced by the backend.
class SettingsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final bool notEnforced;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.notEnforced = false,
  });

  @override
  Widget build(BuildContext context) {
    // The fill lives on the Material, not on a DecoratedBox: an opaque
    // decoration between a ListTile (the switches below) and its nearest
    // Material hides ink splashes and trips a framework assertion.
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (notEnforced) const _NotEnforcedBadge(),
            ],
          ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppDimensions.paddingMedium),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NotEnforcedBadge extends StatelessWidget {
  const _NotEnforcedBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Saved and remembered, but the booking flow does not act on '
          'these values yet.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
            SizedBox(width: 4),
            Text(
              'Not yet enforced',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
