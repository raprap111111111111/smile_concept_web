// lib/presentation/route/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router_notifier.dart';
import 'router_redirect.dart';
import 'route_names.dart';
import 'routes/public_routes.dart';
import 'routes/shell_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) => handleRedirect(ref, state),
    routes: [
      ...publicRoutes,
      shellRoutes,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.goNamed(RouteNames.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  ref.onDispose(notifier.dispose);
  return router;
});