// lib/presentation/pages/unauthorized/unauthorized_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/permission_provider.dart';
import '../../route/route_permissions.dart';
import '/../../../presentation/theme/app_colors.dart';

class UnauthorizedPage extends ConsumerWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              '403 - Unauthorized',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You don't have permission to access this page.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Take Me Back'),
              // Not hardcoded to the dashboard: a user who lacks dashboard.view
              // would bounce straight back here.
              onPressed: () => context.go(
                RoutePermissions.landingFor(ref.read(permissionServiceProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}