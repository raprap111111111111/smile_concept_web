import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class LandingPrimaryButton extends StatelessWidget {
  const LandingPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined,
          size: AppDimensions.iconSizeMedium),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        textStyle: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }
}

class LandingIconBadge extends StatelessWidget {
  const LandingIconBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.iconBadgeSize,
      width: AppDimensions.iconBadgeSize,
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Icon(icon, color: AppColors.primaryDark, size: AppDimensions.iconSize),
    );
  }
}

class LandingPill extends StatelessWidget {
  const LandingPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.accentWithOpacity(0.5)),
      ),
      child: Text(text, style: AppTextStyles.pill),
    );
  }
}

class LandingNavLink extends StatelessWidget {
  const LandingNavLink({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(label, style: AppTextStyles.navLink),
    );
  }
}

class LandingSection extends StatelessWidget {
  const LandingSection({
    super.key,
    required this.title,
    required this.body,
    required this.child,
  });

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingSection,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 14),
                    Text(body, style: AppTextStyles.sectionBody),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class LandingContentWrapper extends StatelessWidget {
  const LandingContentWrapper({
    super.key,
    required this.child,
    this.color,
    this.padding,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLarge),
            child: child,
          ),
        ),
      ),
    );
  }
}