// lib/presentation/pages/home/home_page.dart
// FULL FILE — complete replacement:

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../route/route_names.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AuthState is a plain class — NO .when(), NO .valueOrNull
    final authState = ref.watch(authStateProvider);
    final user = authState.user; // direct access

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              // Router handles redirect automatically — no manual goNamed needed
            },
          ),
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.calendar_today,
                          title: 'Appointments',
                          onTap: () =>
                              context.pushNamed(RouteNames.appointments),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.people,
                          title: 'Patients',
                          onTap: () => context.pushNamed(RouteNames.patients),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.receipt,
                          title: 'Invoices',
                          onTap: () => context.pushNamed(RouteNames.invoices),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.settings,
                          title: 'Settings',
                          onTap: () => context.pushNamed(RouteNames.settings),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}