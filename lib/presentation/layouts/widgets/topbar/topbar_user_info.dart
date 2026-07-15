// lib/presentation/layouts/widgets/topbar/topbar_user_info.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth/auth_provider.dart';
import '../../../route/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class TopbarUserInfo extends ConsumerStatefulWidget {
  const TopbarUserInfo({super.key});

  @override
  ConsumerState<TopbarUserInfo> createState() => _TopbarUserInfoState();
}

class _TopbarUserInfoState extends ConsumerState<TopbarUserInfo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;

    return Row(
      children: [
        // ─── Clickable user info → profile ─────────────────────────
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => context.goNamed(RouteNames.profile),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _isHovered ? AppColors.surface : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                border: Border.all(
                  color: _isHovered ? AppColors.line : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accentWithOpacity(0.35),
                    radius: 19,
                    backgroundImage: user?.profilePhotoUrl != null
                        ? NetworkImage(user!.profilePhotoUrl!)
                        : null,
                    child: user?.profilePhotoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.primaryDark,
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
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        user?.role ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ─── Logout button ──────────────────────────────────────────
        Tooltip(
          message: 'Logout',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _confirmLogout(context),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Confirm logout dialog (light themed) ──────────────────────────
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          side: const BorderSide(color: AppColors.line),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                side: const BorderSide(color: AppColors.line),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.goNamed(RouteNames.login);
    }
  }
}