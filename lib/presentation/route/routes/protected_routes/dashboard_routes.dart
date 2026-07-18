// lib/presentation/route/routes/protected_routes/dashboard_routes.dart

import 'package:go_router/go_router.dart';

import '/presentation/pages/dashboard/dashboard_page.dart';
import '/presentation/pages/clinical_records/clinical_records_page.dart';
import '/presentation/route/route_names.dart';

final List<GoRoute> dashboardRoutes = [
  GoRoute(
    path: '/dashboard',
    name: RouteNames.dashboard,
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/clinical-records',
    name: RouteNames.clinicalRecords,
    builder: (context, state) => const ClinicalRecordsPage(),
  ),
];