// lib/presentation/route/routes/protected_routes/misc_routes.dart

import 'package:go_router/go_router.dart';

import '../../../pages/activity_logs/activity_logs_page.dart';
import '../../../pages/appointment_settings/appointment_settings_page.dart';
import '../../../pages/branch/branches_page.dart';
import '../../../pages/doctor_schedules/doctor_schedules_pages.dart';
import '/presentation/pages/doctors/doctor_detail_page.dart';
import '../../../pages/doctors/doctors_page.dart';
import '../../../pages/notifications/notifications_page.dart';
import '../../../pages/profile/profile_page.dart';
import '../../../pages/roles/roles_permissions_page.dart';
import '../../../pages/settings/settings_page.dart';
import '../../../pages/users/users_page.dart';
import '../../page_transitions.dart';
import '../../route_names.dart';

final List<GoRoute> miscRoutes = [
  // ═══ DOCTORS ══════════════════════════════════════════════
  GoRoute(
    path: '/doctors',
    name: RouteNames.doctors,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const DoctorsPage(),
    ),
    routes: [
      // ✅ Nested /doctors/:id — no name, just path
      GoRoute(
        path: ':id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return FadeThroughPage(
              key: state.pageKey,
              child: const DoctorsPage(),
            );
          }
          return FadeThroughPage(
            key: state.pageKey,
            child: DoctorDetailPage(doctorId: id),
          );
        },
      ),
    ],
  ),

  GoRoute(
    path: '/doctor-schedules',
    name: RouteNames.doctorSchedules,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const DoctorSchedulePage(),
    ),
  ),
  GoRoute(
    path: '/profile',
    name: RouteNames.profile,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const ProfilePage(),
    ),
  ),
  GoRoute(
    path: '/settings',
    name: RouteNames.settings,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const SettingsPage(),
    ),
  ),
  GoRoute(
    path: '/appointment-settings',
    name: RouteNames.appointmentSettings,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const AppointmentSettingsPage(),
    ),
  ),
  GoRoute(
    path: '/roles',
    name: RouteNames.roles,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const RolesPermissionsPage(),
    ),
  ),
  GoRoute(
    path: '/users',
    name: RouteNames.users,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const UsersPage(),
    ),
  ),
  GoRoute(
    path: '/branches',
    name: RouteNames.branches,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const BranchesPage(),
    ),
  ),
  GoRoute(
    path: '/notifications',
    name: RouteNames.notifications,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const NotificationsPage(),
    ),
  ),
  GoRoute(
    path: '/activity-logs',
    name: RouteNames.activityLogs,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const ActivityLogsPage(),
    ),
  ),
];
