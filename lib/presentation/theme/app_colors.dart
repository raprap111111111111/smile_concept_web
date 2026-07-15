import 'package:flutter/material.dart';

class AppColors {
  // Primary Teal / Dental Accent
  static const Color primary = Color(0xFF0E8FA3);
  static const Color primaryDark = Color(0xFF096577);
  static const Color primaryLight = Color(0xFF8BCBC1);

  // Secondary
  static const Color secondary = Color(0xFF12313A);
  static const Color secondaryDark = Color(0xFF0A1F26);

  // Backgrounds
  static const Color background = Colors.white;
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFFF7FBFC);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  // Ink & Text Colors
  static const Color ink = Color(0xFF12313A);
  static const Color text = Color(0xFF12313A);
  static const Color textPrimary = Color(0xFF12313A);
  static const Color textSecondary = Color(0xFF5F7480);
  static const Color textMuted = Color(0xFF5F7480);
  static const Color textTertiary = Color(0xFF8A9BA3);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkMuted = Color(0xFFD7F1F3);

  // Border & Divider
  static const Color border = Color(0xFFDDE9ED);
  static const Color divider = Color(0xFFDDE9ED);
  static const Color line = Color(0xFFDDE9ED);

  // Accent
  static const Color accent = Color(0xFF8BCBC1);
  static const Color accentLight = Color(0xFFE8F5F0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Color statusBooked = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFF44336);
  static const Color statusNoShow = Color(0xFFFF9800);
  static const Color statusPending = Color(0xFFFFC107);

  // Card Shadow
  static const Color cardShadow = Color(0x14000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E8FA3), Color(0xFF096577)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8BCBC1), Color(0xFF0E8FA3)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Helpers
  static Color accentWithOpacity(double opacity) =>
      accent.withValues(alpha: opacity);

  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
}