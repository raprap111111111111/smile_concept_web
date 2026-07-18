// lib/presentation/route/routes/shell_routes.dart

import 'package:go_router/go_router.dart';

import '../../layouts/main_layout.dart';
import 'protected_routes/dashboard_routes.dart';
import 'protected_routes/patient_routes.dart';
import 'protected_routes/appointment_routes.dart';
import 'protected_routes/prescription_routes.dart';
import 'protected_routes/treatment_routes.dart';
import 'protected_routes/invoice_routes.dart';
import 'protected_routes/misc_routes.dart';
import 'protected_routes/inventory_routes.dart';

final shellRoutes = ShellRoute(
  builder: (context, state, child) => MainLayout(child: child),
  routes: [
    ...dashboardRoutes,
    ...patientRoutes,
    ...appointmentRoutes,
    ...prescriptionRoutes,
    ...treatmentRoutes,
    ...invoiceRoutes,
    ...inventoryRoutes,
    ...miscRoutes,
  ],
);