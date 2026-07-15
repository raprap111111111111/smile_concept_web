import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: 28,
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                Text('SmileConcept Dental', style: AppTextStyles.footerBrand),
                Text(
                  'Modern care for healthier, brighter smiles.',
                  style: AppTextStyles.footerCaption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}