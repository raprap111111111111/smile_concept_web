// lib/presentation/route/routes/protected_routes/appointment_routes.dart

import 'package:go_router/go_router.dart';

import '/presentation/pages/appointments/appointments_page.dart';
import '/presentation/pages/appointments/book_appointment_page.dart';
import '/presentation/route/route_names.dart';
import '/presentation/route/page_transitions.dart';

final List<GoRoute> appointmentRoutes = [
  GoRoute(
    path: '/appointments',
    name: RouteNames.appointments,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const AppointmentsPage(),
    ),
  ),
  GoRoute(
    path: '/book-appointment',
    name: RouteNames.bookAppointment,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const BookAppointmentPage(),
    ),
  ),
];