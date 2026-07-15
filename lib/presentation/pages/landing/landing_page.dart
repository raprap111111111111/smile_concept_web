import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/auth_provider.dart';
import '../../route/route_names.dart';
import 'widgets/landing_appointment_section.dart';
import 'widgets/landing_care_section.dart';
import 'widgets/landing_footer.dart';
import 'widgets/landing_hero_section.dart';
import 'widgets/landing_navigation.dart';
import 'widgets/landing_services_section.dart';
import 'widgets/landing_trust_strip.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            LandingNavigation(onBook: () => _book(context, ref)),
            LandingHeroSection(onBook: () => _book(context, ref)),
            const LandingTrustStrip(),
            const LandingServicesSection(),
            const LandingCareSection(),
            LandingAppointmentSection(onBook: () => _book(context, ref)),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  void _book(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);

    if (authState.isAuthenticated) {
      context.pushNamed(RouteNames.bookAppointment);
      return;
    }

    context.pushNamed(RouteNames.register);
  }
}
