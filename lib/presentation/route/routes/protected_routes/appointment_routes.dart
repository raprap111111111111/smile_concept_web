// lib/presentation/route/routes/protected_routes/appointment_routes.dart

import 'package:go_router/go_router.dart';

import '/presentation/pages/appointments/appointments_page.dart';
import '/presentation/pages/appointments/book_appointment_page.dart';
import '/presentation/route/route_names.dart';

final List<GoRoute> appointmentRoutes = [
  GoRoute(
    path: '/appointments',
    name: RouteNames.appointments,
    builder: (context, state) => const AppointmentsPage(),
  ),
  GoRoute(
    path: '/book-appointment',
    name: RouteNames.bookAppointment,
    builder: (context, state) => const BookAppointmentPage(),
  ),
];