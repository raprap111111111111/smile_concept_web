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
// import '../pages/auth/forgot_password_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/appointments/appointments_page.dart';
// import '../pages/patients/patients_page.dart';
// import '../pages/invoices/invoices_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/roles/roles_permissions_page.dart';
import '../pages/doctors/doctors_page.dart';
// ✅ NEW: Invoices pages
import '../pages/invoices/invoices_page.dart';
import '../pages/invoices/invoice_detail_page.dart';
import '/../../presentation/pages/notifications/notifications_page.dart';

// ✅ Patients pages
import '../../presentation/pages/patients/patient_list_page.dart';
import '../../presentation/pages/patients/patient_detail_page.dart';
import '../../presentation/pages/patients/patient_form_page.dart';
import '/../../presentation/pages/users/users_page.dart';
import '/../../presentation/pages/branch/branches_page.dart';

import '/../../presentation/pages/doctor_schedules/doctor_schedules_pages.dart';
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

      // ── Public routes (accessible without login) ────────────
      final publicRoutes = ['/', '/login', '/register', '/forgot-password'];
      final isPublic = publicRoutes.contains(location);

      // ── Still checking session ──────────────────────────────
      if (authState.isInitial || authState.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      // ── Authenticated ───────────────────────────────────────
      if (authState.isAuthenticated) {
        // If on splash / auth pages → go to dashboard
        if (location == '/splash' ||
            location == '/login' ||
            location == '/register') {
          return '/dashboard';
        }
        return null; // stay wherever they are
      }

      // ── Unauthenticated ─────────────────────────────────────
      if (!isPublic && location != '/splash') {
        return '/login';
      }

      // From splash → landing (or login)
      if (location == '/splash') {
        return '/';
      }

      return null;
    },
    routes: [
      // ─── Public Routes ──────────────────────────────────────
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
      // GoRoute(
      //   path: '/forgot-password',
      //   name: RouteNames.forgotPassword,
      //   builder: (context, state) => const ForgotPasswordPage(),
      // ),

      // ─── Protected Routes (wrapped in MainLayout with sidebar) ──
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/appointments',
            name: RouteNames.appointments,
            builder: (context, state) => const AppointmentsPage(),
          ),
          GoRoute(
            path: '/doctors',
            name: RouteNames.doctors,
            builder: (context, state) => const DoctorsPage(),
          ),
          GoRoute(
            path: '/doctor-schedules',
            name: RouteNames.doctorSchedules,
            builder: (context, state) => const DoctorSchedulePage(),
          ),
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
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/roles',
            name: RouteNames.roles,
            builder: (context, state) => const RolesPermissionsPage(),
          ),
          GoRoute(
            path: '/users',
            name: RouteNames.users,
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: '/branches',
            name: RouteNames.branches,
            builder: (context, state) => const BranchesPage(),
          ),

          // ✅ Notification bell route
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

// ─── Auth listener for GoRouter refresh ──────────────────────────────────────
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        print('Auth changed: ${previous?.status} → ${next.status}');
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
