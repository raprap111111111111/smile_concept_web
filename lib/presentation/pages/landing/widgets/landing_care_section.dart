import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'landing_shared_widgets.dart';

class LandingCareSection extends StatelessWidget {
  const LandingCareSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingSection,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact =
                    constraints.maxWidth < AppDimensions.careBreakpoint;

                final content = const _CareContent();
                final list = const _CarePointList();

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 30),
                      list,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: AppDimensions.paddingXXL),
                    Expanded(child: list),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CareContent extends StatelessWidget {
  const _CareContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LandingPill(text: 'Patient-first experience'),
        SizedBox(height: 18),
        Text(
          'A calmer visit from booking to follow-up.',
          style: AppTextStyles.headlineLarge,
        ),
        SizedBox(height: 18),
        Text(
          'The landing experience now reflects what patients expect from a '
          'professional dental clinic: clarity, trust, fast action, and '
          'reassurance before they book.',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _CarePointList extends StatelessWidget {
  const _CarePointList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CarePoint(
          icon: Icons.event_available_outlined,
          title: 'Simple appointment flow',
          body:
              'A direct booking CTA appears in the header, hero, and final section.',
        ),
        _CarePoint(
          icon: Icons.description_outlined,
          title: 'Transparent treatment planning',
          body:
              'Patients can understand services before creating an account.',
        ),
        _CarePoint(
          icon: Icons.notifications_active_outlined,
          title: 'Helpful reminders',
          body:
              'A clean bridge into the patient portal and clinic management system.',
        ),
      ],
    );
  }
}

class _CarePoint extends StatelessWidget {
  const _CarePoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppDimensions.cardPaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LandingIconBadge(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 7),
                Text(body, style: AppTextStyles.cardBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}