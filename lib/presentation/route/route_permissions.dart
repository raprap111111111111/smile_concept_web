// lib/presentation/route/route_permissions.dart

import '/../core/permissions/app_permissions.dart';
import '../providers/auth/permission_provider.dart';

/// Permission requirements for every protected path.
///
/// The sidebar hides links a user cannot use, but hiding a link is not a guard:
/// the route is still reachable by direct URL, by a post-login redirect, or by
/// any `context.go` that was written before the permission existed. This map is
/// the guard, and [SidebarNavConfig] describes only what to *show*.
///
/// A path is allowed when the user holds ANY of its listed permissions. An empty
/// list means "any authenticated user".
class RoutePermissions {
  RoutePermissions._();

  static const String unauthorizedPath = '/unauthorized';

  /// Where an authenticated user goes when no destination was requested.
  ///
  /// Ordered by how useful the page is as a home screen. The first entry the
  /// user can actually open wins, so a patient without `dashboard.view` lands on
  /// their appointments instead of bouncing off a page they cannot see.
  static const List<String> _landingCandidates = [
    '/dashboard',
    '/appointments',
    '/prescriptions',
    '/treatment-plans',
    '/invoices',
    '/patients',
    '/profile',
  ];

  /// Longest matching path prefix wins, so `/patients/new` is checked against
  /// `patient.create` rather than falling back to `/patients`.
  static const Map<String, List<String>> _requirements = {
    // ── Always available to an authenticated user ──────────────
    '/profile': [],
    unauthorizedPath: [],

    // ── Main ───────────────────────────────────────────────────
    '/dashboard': [Perm.dashboardView],
    '/appointments': [Perm.appointmentViewAny, Perm.appointmentView],
    '/book-appointment': [
      Perm.appointmentCreate,
      Perm.appointmentCreateForOthers
    ],
    // The patient-facing booking form. Registered so it is guarded like every
    // other booking entry point — an unregistered path is waved through.
    '/appointment-patient-form': [
      Perm.appointmentCreate,
      Perm.appointmentCreateForOthers,
    ],

    // ── Clinical ───────────────────────────────────────────────
    '/clinical-records': [
      Perm.clinicalNoteViewAny,
      Perm.dentalChartViewAny,
      Perm.dentalChartView,
    ],
    '/patients/new': [Perm.patientCreate],
    '/patients/:id/edit': [Perm.patientUpdate],
    '/patients': [Perm.patientViewAny, Perm.patientView],
    '/doctors': [Perm.doctorViewAny],
    '/doctor-schedules': [Perm.doctorScheduleViewAny],
    '/prescriptions/new': [Perm.prescriptionCreate],
    '/prescriptions': [Perm.prescriptionViewAny, Perm.prescriptionView],
    '/treatments/new': [Perm.treatmentCreate],
    '/treatments': [Perm.treatmentViewAny, Perm.treatmentView],
    '/treatment-plans/new': [Perm.treatmentPlanCreate],
    '/treatment-plans': [Perm.treatmentPlanViewAny, Perm.treatmentPlanView],
    '/lab-cases': [Perm.labCaseViewAny],
    '/patient-attachments/upload': [
      Perm.patientAttachmentCreate,
    ],
    '/patient-attachments/:id': [
      Perm.patientAttachmentViewAny,
      Perm.patientAttachmentView,
    ],
    '/patient-attachments': [
      Perm.patientAttachmentViewAny,
      Perm.patientAttachmentView,
    ],

    // ── Billing ────────────────────────────────────────────────
    '/invoices': [Perm.invoiceViewAny, Perm.invoiceView],
    '/payments': [Perm.paymentViewAny, Perm.paymentView],

    // ── Operations ─────────────────────────────────────────────
    '/inventory/new': [Perm.inventoryCreate],
    '/inventory': [Perm.inventoryViewAny, Perm.inventoryView],
    '/items/new': [Perm.inventoryCreate],
    '/items': [Perm.inventoryViewAny, Perm.inventoryView],
    '/branches': [Perm.branchViewAny],

    // ── System ─────────────────────────────────────────────────
    '/users': [Perm.userViewAny],
    '/roles': [Perm.roleViewAny],
    '/activity-logs': [Perm.activityLogViewAny],
    '/settings': [Perm.settingView],
    '/notifications': [Perm.notificationViewAny, Perm.notificationView],
  };

  /// Prefixes sorted most-specific-first. Segment count leads, since a
  /// wildcard rule such as `/patients/:id/edit` is more specific than
  /// `/patients` while being no longer as a string in every case.
  static final List<String> _orderedPaths = _requirements.keys.toList()
    ..sort((a, b) {
      final bySegments = _segments(b).length.compareTo(_segments(a).length);
      if (bySegments != 0) return bySegments;
      return b.length.compareTo(a.length);
    });

  /// Permissions required for [location], or null when nothing is registered.
  ///
  /// Returning null for an unregistered path is deliberate: an unknown path is
  /// a routing bug (a 404), not an authorization decision, and go_router's
  /// error page already handles it.
  static List<String>? requirementsFor(String location) {
    final path = _normalize(location);

    for (final candidate in _orderedPaths) {
      if (_matches(path, candidate)) return _requirements[candidate];
    }
    return null;
  }

  static bool allows(PermissionService perm, String location) {
    final required = requirementsFor(location);

    // Unregistered path: let the router's error page decide.
    if (required == null) return true;
    if (required.isEmpty) return true;

    return perm.canAny(required);
  }

  /// First landing candidate this user can open. `/profile` is the floor —
  /// it requires no permission, so this never returns a blocked path.
  static String landingFor(PermissionService perm) {
    for (final path in _landingCandidates) {
      if (allows(perm, path)) return path;
    }
    return '/profile';
  }

  // ── Helpers ────────────────────────────────────────────────────

  static String _normalize(String location) {
    final path = location.split('?').first.split('#').first;
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  /// True when [path] is [prefix] or a child of it.
  ///
  /// Compared segment by segment, so `/items` never matches a future
  /// `/items-archive`. A `:name` segment in [prefix] stands for exactly one
  /// segment of [path], which is what lets `/patients/:id/edit` cover the
  /// concrete `/patients/42/edit`.
  static bool _matches(String path, String prefix) {
    final pathSegments = _segments(path);
    final prefixSegments = _segments(prefix);

    // A longer prefix cannot be a parent of a shorter path.
    if (prefixSegments.length > pathSegments.length) return false;

    for (var i = 0; i < prefixSegments.length; i++) {
      final expected = prefixSegments[i];
      if (expected.startsWith(':')) continue; // any single segment
      if (expected != pathSegments[i]) return false;
    }
    return true;
  }

  static List<String> _segments(String path) =>
      path.split('/').where((segment) => segment.isNotEmpty).toList();
}
