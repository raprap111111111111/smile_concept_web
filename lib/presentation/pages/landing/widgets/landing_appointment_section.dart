import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class LandingAppointmentSection extends StatelessWidget {
  const LandingAppointmentSection({super.key, required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: 58,
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const SizedBox(
                  width: AppDimensions.ctaCopyMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for your next dental visit?',
                        style: AppTextStyles.headlineOnDark,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Book an appointment and let the team prepare a smooth, personal visit.',
                        style: AppTextStyles.bodyOnDark,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book an appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    textStyle: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primaryDark),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}