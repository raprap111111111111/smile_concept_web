// lib/presentation/route/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth/auth_provider.dart';
import '../layouts/main_layout.dart';

// Pages
import '../pages/splash/splash_page.dart';
import '../pages/landing/landing_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/appointments/appointments_page.dart';
import '../pages/appointments/book_appointment_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/roles/roles_permissions_page.dart';
import '../pages/doctors/doctors_page.dart';
import '../pages/invoices/invoices_page.dart';
import '../pages/invoices/invoice_detail_page.dart';
import '../pages/notifications/notifications_page.dart';
import '../pages/patients/patient_list_page.dart';
import '../pages/patients/patient_detail_page.dart';
import '../pages/patients/patient_form_page.dart';
import '../pages/appointments/appointment_form_patient.dart';
import '../pages/users/users_page.dart';
import '../pages/branch/branches_page.dart';
import '../pages/prescriptions/prescriptions_page.dart';
import '../pages/prescriptions/prescription_form_page.dart';
import '../pages/prescriptions/prescription_detail_page.dart';
import '../pages/treatments/treatments_page.dart';
import '../pages/treatments/treatment_form_page.dart';
import '../pages/treatment_plans/treatment_plans_page.dart';
import '../pages/treatment_plans/treatment_plan_form_page.dart';
import '../pages/doctor_schedules/doctor_schedules_pages.dart';
import '../pages/profile/profile_page.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      print('Redirect → status: ${authState.status}, location: $location');

      final publicRoutes = [
        '/',
        '/login',
        '/register',
        '/forgot-password',
        '/appointment-patient-form',
      ];
      final isPublic = publicRoutes.contains(location);

      // Still loading session
      if (authState.isInitial || authState.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      // Authenticated
      if (authState.isAuthenticated) {
        if (location == '/register') {
          return '/';
        }

        if (location == '/splash' || location == '/login') {
          return '/dashboard';
        }
        return null;
      }

      // Unauthenticated
      if (!isPublic && location != '/splash') {
        return '/login';
      }

      if (location == '/splash') return '/';

      return null;
    },
    routes: [
      // ── Public Routes ─────────────────────────────────────
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
      // Public booking form — intentionally outside the ShellRoute so it
      // renders standalone (no sidebar / nav bar).
      GoRoute(
        path: '/appointment-patient-form',
        name: RouteNames.appointmentPatientForm,
        builder: (context, state) => const AppointmentFormPatient(),
      ),

      // ── Protected Routes ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),

          // Appointments
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

          // ── Treatments (with nested create) ───────────────
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

          // ── Treatment Plans (with nested create) ──────────
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

          // Doctors
          GoRoute(
            path: '/doctors',
            name: RouteNames.doctors,
            builder: (context, state) => const DoctorsPage(),
          ),

          // Doctor Schedules
          GoRoute(
            path: '/doctor-schedules',
            name: RouteNames.doctorSchedules,
            builder: (context, state) => const DoctorSchedulePage(),
          ),

          // ── Patients ──────────────────────────────────────
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

          // ── Invoices ──────────────────────────────────────
          GoRoute(
            path: '/invoices',
            name: RouteNames.invoices,
            builder: (context, state) => const InvoicesPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.invoiceDetail,
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return InvoiceDetailPage(invoiceId: id);
                },
              ),
            ],
          ),

          // ── Prescriptions ─────────────────────────────────
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

          // Profile
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),

          // Roles
          GoRoute(
            path: '/roles',
            name: RouteNames.roles,
            builder: (context, state) => const RolesPermissionsPage(),
          ),

          // Users
          GoRoute(
            path: '/users',
            name: RouteNames.users,
            builder: (context, state) => const UsersPage(),
          ),

          // Branches
          GoRoute(
            path: '/branches',
            name: RouteNames.branches,
            builder: (context, state) => const BranchesPage(),
          ),

          // Notifications
          GoRoute(
            path: '/notifications',
            name: RouteNames.notifications,
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.goNamed(RouteNames.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  ref.onDispose(notifier.dispose);
  return router;
});

// ── Auth Notifier ─────────────────────────────────────────────
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        print(
          'Auth changed: ${previous?.status} → ${next.status}',
        );
        notifyListeners();
      },
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
