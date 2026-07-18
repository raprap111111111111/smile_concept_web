// lib/presentation/pages/profile/widgets/profile_theme.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Light-surface tokens for the profile screen.
///
/// The app root still runs `ThemeData.dark()`, so every colour used on this
/// screen is stated explicitly rather than inherited. Values here are chosen
/// against a white card: anything used for small text clears 4.5:1.
class ProfileTokens {
  const ProfileTokens._();

  // ─── Surfaces ──────────────────────────────────────────────────────────
  /// Page background — a hair cooler than the cards so they read as raised.
  static const Color canvas = Color(0xFFF4F7F9);
  static const Color card = Colors.white;

  /// Fill for avatars, icon tiles and inset rows.
  static const Color subtle = Color(0xFFF1F5F7);
  static const Color hover = Color(0xFFE9F2F4);

  // ─── Lines ─────────────────────────────────────────────────────────────
  static const Color border = AppColors.border; // #DDE9ED
  static const Color divider = Color(0xFFEDF2F4);

  // ─── Text (contrast checked on `card`) ─────────────────────────────────
  static const Color text = AppColors.textPrimary; // #12313A — 13.4:1
  static const Color textMuted = AppColors.textSecondary; // #5F7480 — 4.9:1

  // ─── Brand ─────────────────────────────────────────────────────────────
  /// #0E8FA3 is only 3.8:1 on white — icons, fills and borders only.
  static const Color brand = AppColors.primary;

  /// #096577 is 6.8:1 — use this whenever teal carries small text.
  static const Color brandText = AppColors.primaryDark;
  static const Color brandSubtle = Color(0xFFE6F3F6);

  // ─── Status (text-safe variants) ───────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successSubtle = Color(0xFFE8F4E9);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSubtle = Color(0xFFFCEBEA);
  static const Color warning = Color(0xFF8A5300);
  static const Color warningSubtle = Color(0xFFFDF1DF);
  static const Color neutral = Color(0xFF5F7480);
  static const Color neutralSubtle = Color(0xFFEFF2F4);

  // ─── Elevation ─────────────────────────────────────────────────────────
  /// One soft shadow, not a stack. Enough to lift the card off the canvas
  /// without the blurred halo look.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F1B3A45),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A1B3A45),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const double radius = 14;
  static const double radiusSm = 10;

  /// Minimum hit area for anything tappable.
  static const double minTouchTarget = 44;
}

/// Light theme applied to the profile subtree so Material-owned surfaces
/// (dialogs, text fields, snackbars, tooltips, selection handles) stop
/// resolving against the app's dark root theme.
ThemeData buildProfileTheme(BuildContext context) {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: ProfileTokens.canvas,
    colorScheme: const ColorScheme.light(
      primary: ProfileTokens.brand,
      onPrimary: Colors.white,
      secondary: ProfileTokens.brandText,
      onSecondary: Colors.white,
      surface: ProfileTokens.card,
      onSurface: ProfileTokens.text,
      error: ProfileTokens.danger,
      onError: Colors.white,
      outline: ProfileTokens.border,
    ),
    dividerColor: ProfileTokens.divider,
    textTheme: base.textTheme.apply(
      bodyColor: ProfileTokens.text,
      displayColor: ProfileTokens.text,
    ),
    iconTheme: const IconThemeData(color: ProfileTokens.textMuted),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ProfileTokens.text,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: ProfileTokens.card,
      surfaceTintColor: Colors.transparent,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ProfileTokens.brand,
    ),
  );
}
