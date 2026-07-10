import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common/notification_bell.dart';

import '../providers/auth/auth_provider.dart';
import '../route/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          Container(
            width: 290,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(8, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/smile.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SmileConcept',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.10),
                    height: 1,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SidebarSection(
                          title: 'MAIN',
                          initiallyExpanded: false,
                          children: [
                            SidebarMenuItem(
                              icon: Icons.dashboard_outlined,
                              title: 'Dashboard',
                              routeName: RouteNames.dashboard,
                            ),
                            SidebarMenuItem(
                              icon: Icons.calendar_today_outlined,
                              title: 'Appointments',
                              routeName: RouteNames.appointments,
                            ),
                          ],
                        ),
                        sectionGap(),
                        SidebarSection(
                          title: 'CLINIC',
                          initiallyExpanded: false,
                          children: [
                            SidebarMenuItem(
                              icon: Icons.people_outline,
                              title: 'Patients',
                              routeName: RouteNames.patients,
                            ),
                            SidebarMenuItem(
                              icon: Icons.medical_services_outlined,
                              title: 'Doctors',
                              routeName: RouteNames.doctors,
                            ),
                            SidebarMenuItem(
                              icon: Icons.calendar_month_outlined,
                              title: 'Schedules',
                              routeName: RouteNames.doctorSchedules,
                            ),
                            SidebarMenuItem(
                              icon: Icons.healing_outlined,
                              title: 'Treatments / Services',
                              routeName: RouteNames.services,
                            ),
                            SidebarMenuItem(
                              icon: Icons.folder_shared_outlined,
                              title: 'Clinical Records',
                              routeName: RouteNames.clinical,
                            ),
                          ],
                        ),
                        sectionGap(),
                        SidebarSection(
                          title: 'BILLING',
                          initiallyExpanded: false,
                          children: [
                            SidebarMenuItem(
                              icon: Icons.receipt_long_outlined,
                              title: 'Invoices',
                              routeName: RouteNames.invoices,
                            ),
                            SidebarMenuItem(
                              icon: Icons.payments_outlined,
                              title: 'Payments',
                              routeName: RouteNames.payments,
                            ),
                          ],
                        ),
                        sectionGap(),
                        SidebarSection(
                          title: 'OPERATIONS',
                          initiallyExpanded: false,
                          children: [
                            SidebarMenuItem(
                              icon: Icons.inventory_2_outlined,
                              title: 'Inventory',
                              routeName: RouteNames.inventory,
                            ),
                            SidebarMenuItem(
                              icon: Icons.account_balance_outlined,
                              title: 'Branches',
                              routeName: RouteNames.branches,
                            ),
                            SidebarMenuItem(
                              icon: Icons.science_outlined,
                              title: 'Lab Cases',
                              routeName: RouteNames.labCases,
                            ),
                          ],
                        ),
                        sectionGap(),
                        SidebarSection(
                          title: 'SYSTEM',
                          initiallyExpanded: false,
                          children: [
                            SidebarMenuItem(
                              icon: Icons.people_alt_outlined,
                              title: 'Users',
                              routeName: RouteNames.users,
                            ),
                            SidebarMenuItem(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'Roles & Permissions',
                              routeName: RouteNames.roles,
                            ),
                            SidebarMenuItem(
                              icon: Icons.history_outlined,
                              title: 'Activity Logs',
                              routeName: RouteNames.activityLogs,
                            ),
                            SidebarMenuItem(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              routeName: RouteNames.settings,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentPageTitle(context),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          NotificationBell(
                              // no unreadCount needed anymore
                              ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 19,
                            backgroundImage: user?.profilePhotoUrl != null
                                ? NetworkImage(user!.profilePhotoUrl!)
                                : null,
                            child: user?.profilePhotoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user?.name ?? 'Loading...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                user?.role ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 22),
                          IconButton(
                            tooltip: 'Logout',
                            icon: Icon(
                              Icons.logout,
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                            onPressed: () {
                              ref.read(authStateProvider.notifier).logout();
                              context.goNamed(RouteNames.login);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionGap() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        color: Colors.white.withValues(alpha: 0.06),
        height: 1,
      ),
    );
  }

  String currentPageTitle(BuildContext context) {
    final path = GoRouterState.of(context).uri.toString();

    if (path.contains('/dashboard')) return 'Dashboard';
    if (path.contains('/appointments')) return 'Appointments';
    if (path.contains('/patients')) return 'Patients';
    if (path.contains('/doctors')) return 'Doctors';
    if (path.contains('/doctor-schedules')) return 'Doctor Schedules';
    if (path.contains('/services')) return 'Treatments / Services';
    if (path.contains('/clinical')) return 'Clinical Records';
    if (path.contains('/invoices')) return 'Invoices';
    if (path.contains('/payments')) return 'Payments';
    if (path.contains('/inventory')) return 'Inventory';
    if (path.contains('/branches')) return 'Branches';
    if (path.contains('/lab-cases')) return 'Lab Cases';
    if (path.contains('/users')) return 'Users Management';
    if (path.contains('/roles')) return 'Roles & Permissions';
    if (path.contains('/notifications')) return 'Notifications';
    if (path.contains('/activity-logs')) return 'Activity Logs';
    if (path.contains('/settings')) return 'Settings';

    return 'SmileConcept';
  }
}

class SidebarSection extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;

  const SidebarSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<SidebarSection> createState() => SidebarSectionState();
}

class SidebarSectionState extends State<SidebarSection> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: isExpanded ? 0.0 : -0.25,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.42),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Column(
                  children: widget.children,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routeName;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.routeName,
  });

  @override
  State<SidebarMenuItem> createState() => SidebarMenuItemState();
}

class SidebarMenuItemState extends State<SidebarMenuItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final routePath = '/${widget.routeName}';

    final isActive = currentLocation == routePath ||
        currentLocation.startsWith('$routePath/');

    final activeColor = AppColors.primary;
    final inactiveColor = Colors.white.withValues(alpha: 0.78);

    final backgroundColor = isActive
        ? activeColor.withValues(alpha: 0.16)
        : isHovered
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: isActive ? activeColor : inactiveColor,
              size: 19,
            ),
          ),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? activeColor : Colors.white,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          trailing: isActive
              ? Container(
                  width: 5,
                  height: 26,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )
              : null,
          onTap: () => context.goNamed(widget.routeName),
        ),
      ),
    );
  }
}
