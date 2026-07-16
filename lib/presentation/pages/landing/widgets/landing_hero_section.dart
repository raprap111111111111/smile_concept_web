import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'landing_shared_widgets.dart';

class LandingHeroSection extends StatelessWidget {
  const LandingHeroSection({super.key, required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLarge,
              AppDimensions.heroTopPadding,
              AppDimensions.paddingLarge,
              AppDimensions.heroBottomPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact =
                    constraints.maxWidth < AppDimensions.heroBreakpoint;
                final copy = _HeroCopy(onBook: onBook);
                const image = _HeroImage();

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 32),
                      image,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: AppDimensions.heroGap),
                    const Expanded(child: image),
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

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingPill(text: 'Modern family dental clinic'),
        const SizedBox(height: 22),
        const Text(
          'Confident smiles start with calm, expert care.',
          style: AppTextStyles.heroTitle,
        ),
        const SizedBox(height: 22),
        const Text(
          'SmileConcept combines preventive dentistry, cosmetic treatments, '
          'and simple online booking in one welcoming clinic experience.',
          style: AppTextStyles.heroSubtitle,
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LandingPrimaryButton(
              label: 'Book an appointment',
              onTap: onBook,
            ),
            OutlinedButton.icon(
              onPressed: () => context.goNamed(RouteNames.login),
              icon: const Icon(Icons.lock_outline,
                  size: AppDimensions.iconSizeSmall),
              label: const Text('Patient login'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppDimensions.heroImageAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=1400',
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.cardPaddingSmall),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Row(
                  children: [
                    LandingIconBadge(icon: Icons.verified_outlined),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Gentle treatment planning for every age and smile goal.',
                        style: AppTextStyles.overlayCaption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}