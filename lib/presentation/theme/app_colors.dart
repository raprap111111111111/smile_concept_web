import 'package:flutter/material.dart';

class AppColors {
  // Primary Gold / Luxury Accent
  static const Color primary = Color(0xFFD4AF37);        // Main Gold
  static const Color primaryDark = Color(0xFFB8941F);    // Deeper Gold
  static const Color primaryLight = Color(0xFFF4D06F);   // Lighter Gold

  // Secondary / Accent
  static const Color secondary = Color(0xFF1A1A1A);
  static const Color secondaryDark = Color(0xFF0F0F0F);

  // Backgrounds
  static const Color backgroundDark = Color(0xFF0F0F0F);   // Main dark background
  static const Color surfaceDark = Color(0xFF1A1A1A);      // Slightly lighter surface
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF888888);
  static const Color text = Colors.white;
  static const Color textTertiary = Color(0xFF888888);

  // Status Colors (for appointments, etc.)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Color statusBooked = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFF44336);
  static const Color statusNoShow = Color(0xFFFF9800);
  static const Color statusPending = Color(0xFFFFC107);

  // Divider & Border
  static const Color divider = Color(0xFF333333);
  static const Color border = Color(0xFF444444);

  // Card Shadow
  static const Color cardShadow = Color(0x40000000);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldHorizontalGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF4D06F), Color(0xFFD4AF37)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}