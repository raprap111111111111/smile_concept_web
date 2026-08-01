// lib/presentation/route/routes/protected_routes/lab_case_routes.dart

import 'package:go_router/go_router.dart';
import 'package:smile_concept_web/presentation/pages/lab_cases/lab_case_form_page.dart';
import 'package:smile_concept_web/presentation/pages/lab_cases/lab_cases_page.dart';
import 'package:smile_concept_web/presentation/route/route_names.dart';

final List<RouteBase> labCaseRoutes = [
  GoRoute(
    path: '/lab-cases',
    name: RouteNames.labCases,
    builder: (context, state) => const LabCasesPage(),
    routes: [
      GoRoute(
        path: 'create',
        name: RouteNames.labCaseCreate,
        builder: (context, state) => const LabCaseFormPage(),
      ),
      GoRoute(
        path: ':id/edit',
        name: RouteNames.labCaseEdit,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return LabCaseFormPage(id: id);
        },
      ),
      GoRoute(
        path: ':id',
        name: RouteNames.labCaseView,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return LabCaseFormPage(id: id);
        },
      ),
    ],
  ),
];