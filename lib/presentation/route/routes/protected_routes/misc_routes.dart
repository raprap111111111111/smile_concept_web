// lib/presentation/route/routes/protected_routes/misc_routes.dart

import 'package:go_router/go_router.dart';

import '../../../pages/doctors/doctors_page.dart';
import '../../../pages/doctor_schedules/doctor_schedules_pages.dart';
import '../../../pages/profile/profile_page.dart';
import '../../../pages/settings/settings_page.dart';
import '../../../pages/roles/roles_permissions_page.dart';
import '../../../pages/users/users_page.dart';
import '../../../pages/branch/branches_page.dart';
import '../../../pages/notifications/notifications_page.dart';
import '../../route_names.dart';
import '../../page_transitions.dart';

final List<GoRoute> miscRoutes = [
  GoRoute(
    path: '/doctors',
    name: RouteNames.doctors,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const DoctorsPage(),
    ),
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
];