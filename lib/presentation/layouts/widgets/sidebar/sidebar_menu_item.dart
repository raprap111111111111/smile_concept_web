// lib/presentation/layouts/widgets/sidebar/sidebar_menu_item.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

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
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final routePath = '/${widget.routeName}';
    final isActive = currentLocation == routePath ||
        currentLocation.startsWith('$routePath/');

    // Colors
    const activeColor = AppColors.primaryDark;
    const inactiveTextColor = AppColors.ink;
    const inactiveIconColor = AppColors.textSecondary;

    final backgroundColor = isActive
        ? AppColors.accentWithOpacity(0.22)
        : _isHovered
            ? AppColors.surface
            : Colors.transparent;

    final borderColor = isActive
        ? AppColors.accentWithOpacity(0.5)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: borderColor),
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accentWithOpacity(0.35)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              color: isActive ? activeColor : inactiveIconColor,
              size: 19,
            ),
          ),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? activeColor : inactiveTextColor,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: isActive
              ? Container(
                  width: 4,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
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