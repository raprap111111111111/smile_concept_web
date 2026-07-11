// lib/presentation/layouts/widgets/topbar/page_title.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Resolves the current page title based on the URL path.
class PageTitleResolver {
  PageTitleResolver._();

  static const _titles = <String, String>{
    '/dashboard': 'Dashboard',
    '/appointments': 'Appointments',
    '/patients': 'Patients',
    '/doctors': 'Doctors',
    '/doctor-schedules': 'Doctor Schedules',
    '/services': 'Treatments / Services',
    '/clinical': 'Clinical Records',
    '/invoices': 'Invoices',
    '/payments': 'Payments',
    '/inventory': 'Inventory',
    '/branches': 'Branches',
    '/lab-cases': 'Lab Cases',
    '/users': 'Users Management',
    '/roles': 'Roles & Permissions',
    '/notifications': 'Notifications',
    '/activity-logs': 'Activity Logs',
    '/settings': 'Settings',
    '/prescriptions': 'My Prescriptions',
    '/treatment-plans': 'My Treatment Plans',
  };

  static String resolve(BuildContext context) {
    final path = GoRouterState.of(context).uri.toString();
    for (final entry in _titles.entries) {
      if (path.contains(entry.key)) return entry.value;
    }
    return 'SmileConcept';
  }
}