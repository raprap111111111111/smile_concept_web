// lib/presentation/route/page_transitions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fade-through transition for sidebar navigation.
/// Feels clean and professional for dashboard/admin apps.
class FadeThroughPage extends CustomTransitionPage<void> {
  FadeThroughPage({
    required super.child,
    super.key,
    super.name,
  }) : super(
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 160),
          transitionsBuilder: _fadeThroughBuilder,
        );

  static Widget _fadeThroughBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final scale = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(curved);

    // ── Outgoing page fades out ──
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryCurved),
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      ),
    );
  }
}