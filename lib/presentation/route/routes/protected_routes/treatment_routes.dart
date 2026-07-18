// lib/presentation/route/routes/protected_routes/treatment_routes.dart

import 'package:go_router/go_router.dart';

import '../../../pages/treatments/treatments_page.dart';
import '../../../pages/treatments/treatment_form_page.dart';
import '../../../pages/treatment_plans/treatment_plans_page.dart';
import '../../../pages/treatment_plans/treatment_plan_form_page.dart';
import '../../route_names.dart';

final List<GoRoute> treatmentRoutes = [
  GoRoute(
    path: '/treatments',
    name: RouteNames.treatments,
    builder: (context, state) => const TreatmentsPage(),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.treatmentCreate,
        builder: (context, state) => const TreatmentFormPage(),
      ),
    ],
  ),
  GoRoute(
    path: '/treatment-plans',
    name: RouteNames.treatmentPlans,
    builder: (context, state) => const TreatmentPlansPage(),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.treatmentPlanCreate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TreatmentPlanFormPage(
            patientId: extra?['patient_id'] as int?,
            doctorId: extra?['doctor_id'] as int?,
          );
        },
      ),
    ],
  ),
];