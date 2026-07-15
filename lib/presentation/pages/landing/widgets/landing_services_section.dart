import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'landing_shared_widgets.dart';

class LandingServicesSection extends StatelessWidget {
  const LandingServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      const _ServiceCard(
        icon: Icons.health_and_safety_outlined,
        title: 'Preventive Care',
        body: 'Routine checkups, cleanings, oral exams, and gum health support.',
      ),
      const _ServiceCard(
        icon: Icons.auto_awesome_outlined,
        title: 'Cosmetic Dentistry',
        body:
            'Whitening, veneers, and smile design with natural-looking results.',
      ),
      const _ServiceCard(
        icon: Icons.straighten_outlined,
        title: 'Alignment',
        body:
            'Modern orthodontic options for healthier bite and cleaner smiles.',
      ),
      const _ServiceCard(
        icon: Icons.medical_services_outlined,
        title: 'Restorative Dentistry',
        body: 'Crowns, fillings, and treatment plans that restore comfort.',
      ),
    ];

    return LandingSection(
      title: 'Complete dental care, thoughtfully organized',
      body:
          'Clear services, gentle communication, and a clinic workflow designed around patient comfort.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth < AppDimensions.gridBreakpoint ? 1 : 4;

          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 3.2 : 0.88,
            children: services,
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
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
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LandingIconBadge(icon: icon),
          const SizedBox(height: 18),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Text(body, style: AppTextStyles.cardBody),
        ],
      ),
    );
  }
}