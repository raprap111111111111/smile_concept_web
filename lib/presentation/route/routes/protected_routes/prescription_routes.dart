// lib/presentation/route/routes/protected_routes/prescription_routes.dart

import 'package:go_router/go_router.dart';

import '../../../pages/prescriptions/prescriptions_page.dart';
import '../../../pages/prescriptions/prescription_form_page.dart';
import '../../../pages/prescriptions/prescription_detail_page.dart';
import '../../route_names.dart';

final List<GoRoute> prescriptionRoutes = [
  GoRoute(
    path: '/prescriptions',
    name: RouteNames.prescriptions,
    builder: (context, state) => const PrescriptionsPage(),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.prescriptionCreate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PrescriptionFormPage(
            patientId: extra?['patient_id'] as int?,
            appointmentId: extra?['appointment_id'] as int?,
          );
        },
      ),
      GoRoute(
        path: ':id',
        name: RouteNames.prescriptionDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PrescriptionDetailPage(prescriptionId: id);
        },
      ),
    ],
  ),
];