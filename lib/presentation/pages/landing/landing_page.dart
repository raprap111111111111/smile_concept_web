import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../route/route_names.dart';
import 'widgets/landing_appointment_section.dart';
import 'widgets/landing_care_section.dart';
import 'widgets/landing_footer.dart';
import 'widgets/landing_hero_section.dart';
import 'widgets/landing_navigation.dart';
import 'widgets/landing_services_section.dart';
import 'widgets/landing_trust_strip.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            LandingNavigation(onBook: () => _book(context)),
            LandingHeroSection(onBook: () => _book(context)),
            const LandingTrustStrip(),
            const LandingServicesSection(),
            const LandingCareSection(),
            LandingAppointmentSection(onBook: () => _book(context)),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  void _book(BuildContext context) {
    context.pushNamed(RouteNames.register);
  }
}