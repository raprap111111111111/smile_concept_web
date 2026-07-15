import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'landing_shared_widgets.dart';

class LandingTrustStrip extends StatelessWidget {
  const LandingTrustStrip({super.key});

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
              vertical: 26,
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: const [
                _TrustItem(value: '24/7', label: 'online scheduling'),
                _TrustItem(value: '15+', label: 'dental services'),
                _TrustItem(value: 'Secure', label: 'patient records'),
                _TrustItem(value: 'Clear', label: 'treatment estimates'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.trustItemWidth,
      child: Row(
        children: [
          const LandingIconBadge(icon: Icons.check_circle_outline),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.titleMedium),
              Text(label, style: AppTextStyles.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}