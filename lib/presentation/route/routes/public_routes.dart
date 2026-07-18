// lib/presentation/route/routes/public_routes.dart

import 'package:go_router/go_router.dart';

import '../../pages/splash/splash_page.dart';
import '../../pages/landing/landing_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/appointments/appointment_form_patient.dart';
import '../../pages/unauthorized/unauthorized_page.dart';
import '../route_names.dart';

final List<GoRoute> publicRoutes = [
  GoRoute(
    path: '/splash',
    name: RouteNames.splash,
    builder: (context, state) => const SplashPage(),
  ),
  GoRoute(
    path: '/',
    name: RouteNames.landing,
    builder: (context, state) => const LandingPage(),
  ),
  GoRoute(
    path: '/login',
    name: RouteNames.login,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: '/register',
    name: RouteNames.register,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    path: '/appointment-patient-form',
    name: RouteNames.appointmentPatientForm,
    builder: (context, state) => const AppointmentFormPatient(),
  ),
  // Outside the shell: it carries its own Scaffold, and a user who was just
  // denied a page should not be looking at the nav chrome for that page.
  // Not listed in _publicRoutes, so an unauthenticated hit still bounces home.
  GoRoute(
    path: '/unauthorized',
    name: RouteNames.unauthorized,
    builder: (context, state) => const UnauthorizedPage(),
  ),
];