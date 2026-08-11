// lib/presentation/layouts/widgets/topbar/topbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout/sidebar_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/notification_bell.dart';
import '../../../widgets/common/realtime_status_dot.dart';
import 'page_title.dart';
import 'topbar_user_info.dart';

class Topbar extends ConsumerWidget {
  const Topbar({super.key});

  static const double _height = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);

    return Material(
      color: AppColors.background,
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.line),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── LEFT ──────────────────────────────────────────
            _SidebarToggle(
              collapsed: collapsed,
              onPressed: () =>
                  ref.read(sidebarCollapsedProvider.notifier).toggle(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                PageTitleResolver.resolve(context),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // ── RIGHT (flush to trailing edge) ────────────────
            const RealtimeStatusDot(),
            const NotificationBell(),
            const SizedBox(width: 10),
            Container(width: 1, height: 28, color: AppColors.line),
            const SizedBox(width: 10),
            const TopbarUserInfo(),
          ],
        ),
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onPressed;

  const _SidebarToggle({
    required this.collapsed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      waitDuration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      textStyle: const TextStyle(
        color: AppColors.textOnDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      child: IconButton(
        onPressed: onPressed,
        splashRadius: 22,
        hoverColor: AppColors.surface,
        icon: Icon(
          collapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}