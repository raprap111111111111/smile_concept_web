// lib/presentation/route/router_redirect.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth/auth_provider.dart';
import '../providers/auth/permission_provider.dart';
import 'auth_redirect.dart';
import 'route_permissions.dart';

const _publicRoutes = ['/', '/login', '/register', '/forgot-password'];

// ── Renamed from _handleRedirect to handleRedirect (public) ───────────
String? handleRedirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authStateProvider);
  final location = state.matchedLocation;
  final isPublic = _publicRoutes.contains(location);

  debugPrint('[Redirect] status: ${authState.status}, location: $location');

  // ── Loading ──────────────────────────────────────────────────────────
  if (authState.isInitial || authState.isLoading) {
    return _handleLoadingState(location);
  }

  // ── Authenticated ────────────────────────────────────────────────────
  if (authState.isAuthenticated) {
    return _handleAuthenticatedState(ref, location, state);
  }

  // ── Unauthenticated ──────────────────────────────────────────────────
  return _handleUnauthenticatedState(location, isPublic);
}

// ── Private Helpers ──────────────────────────────────────────────────────

String? _handleLoadingState(String location) {
  if (location == '/login' || location == '/register') return null;
  return location == '/splash' ? null : '/splash';
}

String? _handleAuthenticatedState(
  Ref ref,
  String location,
  GoRouterState state,
) {
  final perm = ref.read(permissionServiceProvider);

  // ── Leaving an auth/splash page ──────────────────────────────────────
  // The old code sent everyone to /dashboard. That is why a patient without
  // dashboard.view still saw the dashboard on first render: the sidebar hid
  // the link, but the redirect walked straight onto the page anyway.
  if (location == '/splash' ||
      location == '/login' ||
      location == '/register') {
    final requested = (location == '/login' || location == '/register')
        ? AuthRedirect.resolve(state.uri.queryParameters)
        : null;

    final landing = RoutePermissions.landingFor(perm);
    if (requested == null) return landing;

    // A `next` param is attacker-supplied and can name a page this user is not
    // allowed to open, so it is permission-checked like any other destination.
    return RoutePermissions.allows(perm, requested) ? requested : landing;
  }

  // ── Any other authenticated destination ──────────────────────────────
  if (!RoutePermissions.allows(perm, location)) {
    debugPrint('[Redirect] blocked $location — missing '
        '${RoutePermissions.requirementsFor(location)}');
    return RoutePermissions.unauthorizedPath;
  }

  return null;
}

String? _handleUnauthenticatedState(String location, bool isPublic) {
  if (location == '/splash') return '/';
  if (!isPublic) return '/';
  return null;
}
