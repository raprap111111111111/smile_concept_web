// lib/presentation/route/routes/protected_routes/patient_routes.dart

import 'package:go_router/go_router.dart';

import '/presentation/pages/patients/patient_list_page.dart';
import '/presentation/pages/patients/patient_detail_page.dart';
import '/presentation/pages/patients/patient_form_page.dart';
import '/presentation/route/route_names.dart';

final List<GoRoute> patientRoutes = [
  GoRoute(
    path: '/patients',
    name: RouteNames.patients,
    builder: (context, state) => const PatientsListPage(),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.patientCreate,
        builder: (context, state) => const PatientFormPage(),
      ),
      GoRoute(
        path: ':id',
        name: RouteNames.patientDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PatientDetailPage(patientId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            name: RouteNames.patientEdit,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return PatientFormPage(patientId: id);
            },
          ),
        ],
      ),
    ],
  ),
];