import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Display
  static const displayLarge = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1.05,
    color: AppColors.ink,
  );

  static const displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.ink,
  );

  static const displaySmall = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.ink,
  );

  // Headline
  static const headlineLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.ink,
  );

  static const headlineMedium = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.ink,
  );

  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.ink,
  );

  // Title
  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.27,
    color: AppColors.ink,
  );

  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.35,
    color: AppColors.ink,
  );

  static const titleSmall = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.35,
    color: AppColors.ink,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.65,
    color: AppColors.textSecondary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  static const bodySmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Label
  static const labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.43,
    color: AppColors.ink,
  );

  static const labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  static const labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Navigation
  static const navLink = TextStyle(
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  // Pill / Badge
  static const pill = TextStyle(
    fontWeight: FontWeight.w800,
    color: AppColors.primaryDark,
  );

  // Hero overrides
  static const heroTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 56,
    height: 1.05,
    fontWeight: FontWeight.w800,
  );

  static const heroSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 18,
    height: 1.65,
  );

  // Section heading
  static const sectionTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 38,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );

  static const sectionBody = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    height: 1.6,
  );

  // On Dark surfaces
  static const headlineOnDark = TextStyle(
    color: Colors.white,
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );

  static const bodyOnDark = TextStyle(
    color: AppColors.textOnDarkMuted,
    fontSize: 16,
    height: 1.6,
  );

  // Card
  static const cardTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const cardBody = TextStyle(
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Overlay caption
  static const overlayCaption = TextStyle(
    color: AppColors.ink,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  // Footer
  static const footerBrand = TextStyle(
    color: AppColors.ink,
    fontWeight: FontWeight.w800,
  );

  static const footerCaption = TextStyle(
    color: AppColors.textSecondary,
  );
}