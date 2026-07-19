// lib/presentation/layouts/widgets/sidebar/sidebar_nav_config.dart

import 'package:flutter/material.dart';
import '/../core/permissions/app_permissions.dart';
import '../../../providers/auth/permission_provider.dart';
import '../../../route/route_names.dart';

class NavItem {
  final IconData icon;
  final String title;
  final String routeName;
  final List<String> permissions;

  const NavItem({
    required this.icon,
    required this.title,
    required this.routeName,
    required this.permissions,
  });
}

class NavSection {
  final String title;
  final List<NavItem> items;

  const NavSection({required this.title, required this.items});
}

class SidebarNavConfig {
  SidebarNavConfig._();

  static List<NavSection> buildFor(PermissionService perm) {
    final isPatient = perm.role == 'patient';

    return [
      // ═══ MAIN ═══════════════════════════════════════════════
      NavSection(
        title: 'MAIN',
        items: [
          const NavItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            routeName: RouteNames.dashboard,
            permissions: [Perm.dashboardView],
          ),
          NavItem(
            icon: Icons.calendar_today_outlined,
            title: isPatient ? 'My Appointments' : 'Appointments',
            routeName: RouteNames.appointments,
            permissions: const [
              Perm.appointmentViewAny,
              Perm.appointmentView,
            ],
          ),
        ],
      ),

      // ═══ MY HEALTH (patient only) ════════════════════════════
      NavSection(
        title: 'MY HEALTH',
        items: [
          const NavItem(
            icon: Icons.medication_outlined,
            title: 'My Prescriptions',
            routeName: RouteNames.prescriptions,
            permissions: [Perm.prescriptionView],
          ),
          const NavItem(
            icon: Icons.assignment_outlined,
            title: 'My Treatment Plans',
            routeName: RouteNames.treatmentPlans,
            permissions: [Perm.treatmentPlanView],
          ),
        ],
      ),

      // ═══ CLINICAL ════════════════════════════════════════════
      NavSection(
        title: 'CLINICAL',
        items: [
          const NavItem(
            icon: Icons.people_outline,
            title: 'Patients',
            routeName: RouteNames.patients,
            permissions: [Perm.patientViewAny],
          ),
          const NavItem(
            icon: Icons.medical_services_outlined,
            title: 'Doctors',
            routeName: RouteNames.doctors,
            permissions: [Perm.doctorViewAny],
          ),
          const NavItem(
            icon: Icons.calendar_month_outlined,
            title: 'Schedules',
            routeName: RouteNames.doctorSchedules,
            permissions: [Perm.doctorScheduleViewAny],
          ),
          const NavItem(
            icon: Icons.healing_outlined,
            title: 'Treatments',
            routeName: RouteNames.treatments,
            permissions: [
              Perm.treatmentViewAny,
              Perm.treatmentView,
            ],
          ),
          NavItem(
            icon: Icons.folder_shared_outlined,
            title: isPatient ? 'My Records' : 'Clinical Records',
            routeName: RouteNames.clinicalRecords,
            permissions: const [
              Perm.clinicalNoteViewAny,
              Perm.dentalChartViewAny,
              Perm.dentalChartView,
            ],
          ),

          // ✅ ADD HERE
          NavItem(
            icon: Icons.attach_file_outlined,
            title: isPatient ? 'My Attachments' : 'Patient Attachments',
            routeName: RouteNames.patientAttachments,
            permissions: const [
              Perm.patientAttachmentViewAny, // staff/admin
              Perm.patientAttachmentView, // patient
            ],
          ),
          NavItem(
            icon: Icons.folder_shared_outlined,
            title: isPatient ? 'My Attachments' : 'Patient Files',
            routeName: isPatient
                ? RouteNames.patientAttachments
                : RouteNames.patientFolders,
            permissions: const [
              Perm.patientAttachmentViewAny, // staff/admin
              Perm.patientAttachmentView, // patient
            ],
          ),
        ],
      ),

      // ✅ Patient Files / Attachments (role-aware)

      // ═══ BILLING ═════════════════════════════════════════════
      NavSection(
        title: 'BILLING',
        items: [
          NavItem(
            icon: Icons.receipt_long_outlined,
            title: isPatient ? 'My Invoices' : 'Invoices',
            routeName: RouteNames.invoices,
            permissions: const [
              Perm.invoiceViewAny,
              Perm.invoiceView,
            ],
          ),
          NavItem(
            icon: Icons.payments_outlined,
            title: isPatient ? 'My Payments' : 'Payments',
            routeName: RouteNames.payments,
            permissions: const [
              Perm.paymentViewAny,
              Perm.paymentView,
            ],
          ),
        ],
      ),

      // ═══ OPERATIONS ══════════════════════════════════════════
      const NavSection(
        title: 'OPERATIONS',
        items: [
          NavItem(
            icon: Icons.medical_services_outlined,
            title: 'Items Catalog',
            routeName: RouteNames.items, // ✅ NEW
            permissions: [Perm.inventoryViewAny],
          ),
          NavItem(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
            routeName: RouteNames.inventory,
            permissions: [Perm.inventoryViewAny],
          ),
          NavItem(
            icon: Icons.account_balance_outlined,
            title: 'Branches',
            routeName: RouteNames.branches,
            permissions: [Perm.branchViewAny],
          ),
          NavItem(
            icon: Icons.science_outlined,
            title: 'Lab Cases',
            routeName: RouteNames.labCases,
            permissions: [Perm.labCaseViewAny],
          ),
        ],
      ),

      // ═══ SYSTEM ══════════════════════════════════════════════
      const NavSection(
        title: 'SYSTEM',
        items: [
          NavItem(
            icon: Icons.people_alt_outlined,
            title: 'Users',
            routeName: RouteNames.users,
            permissions: [Perm.userViewAny],
          ),
          NavItem(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Roles & Permissions',
            routeName: RouteNames.roles,
            permissions: [Perm.roleViewAny],
          ),
          NavItem(
            icon: Icons.history_outlined,
            title: 'Activity Logs',
            routeName: RouteNames.activityLogs,
            permissions: [Perm.activityLogViewAny],
          ),
          NavItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            routeName: RouteNames.settings,
            permissions: [Perm.settingView],
          ),
        ],
      ),
    ];
  }
}
