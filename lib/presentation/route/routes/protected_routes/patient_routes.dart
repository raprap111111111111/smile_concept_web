// lib/presentation/route/routes/protected_routes/patient_routes.dart

import 'package:go_router/go_router.dart';

import '/presentation/pages/patients/patient_list_page.dart';
import '/presentation/pages/patients/patient_detail_page.dart';
import '/presentation/pages/patients/patient_form_page.dart';
import '/presentation/route/route_names.dart';
import '/presentation/route/page_transitions.dart';

final List<GoRoute> patientRoutes = [
  GoRoute(
    path: '/patients',
    name: RouteNames.patients,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const PatientsListPage(),
    ),
    routes: [
      // ── Child routes: no fade, instant transition ──
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