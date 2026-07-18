// lib/presentation/route/router_redirect.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth/auth_provider.dart';
import 'auth_redirect.dart';

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
    return _handleAuthenticatedState(location, state);
  }

  // ── Unauthenticated ──────────────────────────────────────────────────
  return _handleUnauthenticatedState(location, isPublic);
}

// ── Private Helpers ──────────────────────────────────────────────────────

String? _handleLoadingState(String location) {
  if (location == '/login' || location == '/register') return null;
  return location == '/splash' ? null : '/splash';
}

String? _handleAuthenticatedState(String location, GoRouterState state) {
  if (location == '/login' || location == '/register') {
    final next = AuthRedirect.resolve(state.uri.queryParameters);
    if (next != null) return next;
  }

  if (location == '/splash' ||
      location == '/login' ||
      location == '/register') {
    return '/dashboard';
  }

  return null;
}

String? _handleUnauthenticatedState(String location, bool isPublic) {
  if (location == '/splash') return '/';
  if (!isPublic) return '/';
  return null;
}