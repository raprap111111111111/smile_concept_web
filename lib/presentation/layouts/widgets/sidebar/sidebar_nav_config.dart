// lib/presentation/layouts/widgets/sidebar/sidebar_nav_config.dart

import 'package:flutter/material.dart';
import '../../../providers/auth/permission_provider.dart';
import '../../../route/route_names.dart';
import 'package:smile_concept_web/core/permissions/app_permissions.dart';

class NavItem {
  final IconData icon;
  final String title;
  final String routeName;
  final List<String> permissions;
  final List<String> activeRouteNames;

  const NavItem({
    required this.icon,
    required this.title,
    required this.routeName,
    required this.permissions,
    this.activeRouteNames = const [],
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
      const NavSection(
        title: 'MY HEALTH',
        items: [
          NavItem(
            icon: Icons.medication_outlined,
            title: 'My Prescriptions',
            routeName: RouteNames.prescriptions,
            permissions: [
              Perm.prescriptionViewOwn,
              Perm.prescriptionViewAny,
            ],
          ),
          NavItem(
            icon: Icons.assignment_outlined,
            title: 'My Treatment Plans',
            routeName: RouteNames.treatmentPlans,
            permissions: [
              Perm.treatmentPlanView,
              Perm.treatmentPlanViewOwn,
            ],
          ),
          NavItem(
            icon: Icons.fact_check_outlined,
            title: 'My Consent Forms',
            routeName: RouteNames.consents,
            permissions: [
              Perm.consentFormViewOwn,
              Perm.consentFormViewAny,
            ],
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
          // NavItem(
          //   icon: Icons.folder_shared_outlined,
          //   title: isPatient ? 'My Records' : 'Clinical Records',
          //   routeName: RouteNames.clinicalRecords,
          //   activeRouteNames: const [
          //     RouteNames.clinicalRecords,
          //   ],
          //   permissions: const [
          //     Perm.clinicalNoteViewAny,
          //     Perm.dentalChartViewAny,
          //     Perm.dentalChartView,
          //   ],
          // ),
          NavItem(
            icon: Icons.folder_copy_outlined,
            title: isPatient ? 'My Files' : 'Patient Files',
            routeName: isPatient
                ? RouteNames.patientAttachments
                : RouteNames.patientFolders,
            activeRouteNames: [
              RouteNames.patientFolders,
              RouteNames.patientAttachments,
            ],
            permissions: const [
              Perm.patientAttachmentViewAny,
              Perm.patientAttachmentView,
            ],
          ),
        ],
      ),

      // // ═══ BILLING ═════════════════════════════════════════════
      // NavSection(
      //   title: 'BILLING',
      //   items: [
      //     NavItem(
      //       icon: Icons.receipt_long_outlined,
      //       title: isPatient ? 'My Invoices' : 'Invoices',
      //       routeName: RouteNames.invoices,
      //       permissions: const [
      //         Perm.invoiceViewAny,
      //         Perm.invoiceView,
      //       ],
      //     ),
      //     NavItem(
      //       icon: Icons.payments_outlined,
      //       title: isPatient ? 'My Payments' : 'Payments',
      //       routeName: RouteNames.payments,
      //       permissions: const [
      //         Perm.paymentViewAny,
      //         Perm.paymentView,
      //       ],
      //     ),
      //   ],
      // ),

      // ═══ OPERATIONS ══════════════════════════════════════════
      const NavSection(
        title: 'OPERATIONS',
        items: [
          NavItem(
            icon: Icons.medical_services_outlined,
            title: 'Items Catalog',
            routeName: RouteNames.items,
            // Kept in step with the router's /items rule, which accepts either
            // family. Gating on viewAny alone also hid the link from a user who
            // holds only `view` and can in fact open the page by URL.
            permissions: [
              Perm.itemViewAny,
              Perm.itemView,
              Perm.inventoryViewAny,
              Perm.inventoryView,
            ],
          ),
          NavItem(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
            routeName: RouteNames.inventory,
            permissions: [Perm.inventoryViewAny, Perm.inventoryView],
          ),
          NavItem(
            icon: Icons.account_balance_outlined,
            title: 'Branches',
            routeName: RouteNames.branches,
            permissions: [Perm.branchViewAny],
          ),
          // NavItem(
          //   icon: Icons.science_outlined,
          //   title: 'Lab Cases',
          //   routeName: RouteNames.labCases,
          //   permissions: [Perm.labCaseViewAny],
          // ),
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
          // NavItem(
          //   icon: Icons.event_note_outlined,
          //   title: 'Appointment Settings',
          //   routeName: RouteNames.appointmentSettings,
          //   permissions: [Perm.settingUpdate],
          // ),
          // NavItem(
          //   icon: Icons.inventory_outlined,
          //   title: 'Inventory Settings',
          //   routeName: RouteNames.inventorySettings,
          //   permissions: [Perm.settingUpdate],
          // ),
          NavItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            routeName: RouteNames.settings,
            activeRouteNames: [
              RouteNames.settings,
              RouteNames.appointmentSettings,
              RouteNames.inventorySettings,
            ],
            permissions: [
              Perm.settingView,
              Perm.settingUpdate,
            ],
          ),
        ],
      ),
    ];
  }
}
