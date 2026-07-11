// lib/presentation/layouts/widgets/sidebar/sidebar_menu_item.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';

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

    final activeColor = AppColors.primary;
    final inactiveColor = Colors.white.withValues(alpha: 0.78);

    final backgroundColor = isActive
        ? activeColor.withValues(alpha: 0.16)
        : _isHovered
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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