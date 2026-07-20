// lib/presentation/layouts/widgets/sidebar/sidebar_menu_item.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

class SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routeName;
  final List<String> activeRouteNames;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.routeName,
    this.activeRouteNames = const [],
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _hoverAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    if (!_isHovered) {
      _isHovered = true;
      _controller.forward();
    }
  }

  void _onExit(PointerEvent _) {
    if (_isHovered) {
      _isHovered = false;
      _controller.reverse();
    }
  }

  bool _checkIsActive(String currentLocation) {
    final routesToCheck = <String>{
      widget.routeName,
      ...widget.activeRouteNames,
    };

    for (final routeName in routesToCheck) {
      // Path-based match: /routeName or /routeName/...
      final routePath = '/$routeName';
      if (currentLocation == routePath ||
          currentLocation.startsWith('$routePath/')) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isActive = _checkIsActive(currentLocation);

    const activeColor = AppColors.primaryDark;
    const inactiveTextColor = AppColors.ink;
    const inactiveIconColor = AppColors.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: _onEnter,
      onExit: _onExit,
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          final t = _hoverAnimation.value;

          final Color bgColor = isActive
              ? AppColors.accentWithOpacity(0.22)
              : Color.lerp(Colors.transparent, AppColors.surface, t)!;

          final Color borderColor = isActive
              ? AppColors.accentWithOpacity(0.5)
              : Colors.transparent;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            onTap: () => context.goNamed(widget.routeName),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              child: Row(
                children: [
                  // ── Icon container ──────────────────────────
                  Container(
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
                      color:
                          isActive ? activeColor : inactiveIconColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Label ───────────────────────────────────
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isActive ? activeColor : inactiveTextColor,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // ── Active pill ─────────────────────────────
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}