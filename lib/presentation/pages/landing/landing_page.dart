import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/auth_provider.dart';
import '../../route/auth_redirect.dart';
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
            const LandingNavigation(),
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

  /// Single entry point for every booking CTA on this page. Booking requires an
  /// account, so unauthenticated visitors log in first — carrying the booking
  /// form as `next` so auth is a detour rather than a dead end. Login, not
  /// register: returning patients are the common case, and the login page
  /// offers a register link that keeps `next` intact.
  void _book(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);

    // go, not push: an imperatively pushed route leaves the router's location
    // at '/', so the redirect guard can't tell where the user actually is and
    // bounces them to /splash — and from there to their landing page.
    if (authState.isAuthenticated) {
      context.goNamed(RouteNames.appointmentPatientForm);
      return;
    }

    context.go(AuthRedirect.path('/login', AuthRedirect.bookingForm));
  }
}
