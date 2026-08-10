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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(
          bottom: BorderSide(color: AppColors.line),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Sidebar toggle ────────────────────────────────
          _SidebarToggle(
            collapsed: collapsed,
            onPressed: () =>
                ref.read(sidebarCollapsedProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),

          // ── Page title (takes remaining space, ellipsizes) ─
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

          const SizedBox(width: 8),

          // ── Right actions (may shrink on narrow widths) ───
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RealtimeStatusDot(),
                const NotificationBell(),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.line,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: TopbarUserInfo(),
                ),
              ],
            ),
          ),
        ],
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