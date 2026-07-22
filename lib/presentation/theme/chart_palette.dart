// lib/presentation/theme/chart_palette.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colour tokens for the dashboard charts.
///
/// The status slots below were validated as a categorical palette against the
/// white card surface these charts render on (OKLCH lightness band, chroma
/// floor, protan/deuteran separation, contrast). They are ordered so that no
/// two hard-to-separate hues ever touch inside the stacked status bar —
/// `completed → confirmed → pending → cancelled`. Reordering the stack without
/// re-validating breaks colour-blind separation, so keep [statusOrder] as the
/// single source of stacking order.
///
/// `pending` sits just below 3:1 against white by design; every chart that
/// uses it ships a visible labelled legend as the relief channel.
class ChartPalette {
  const ChartPalette._();

  /// The surface every chart is drawn on — also the colour of the 2px gaps
  /// that separate touching marks.
  static const Color surface = AppColors.background;

  // ── Single-series hue ───────────────────────────────────
  // One series means one colour and no legend; the card title names it.
  static const Color primarySeries = AppColors.primary; // #0E8FA3
  static const Color primarySeriesWash = Color(0x1A0E8FA3); // ~10% opacity

  /// Bars outside the emphasised bucket (e.g. hours that are not "now").
  static const Color deemphasis = Color(0xFFCFDDE2);

  // ── Chart chrome ────────────────────────────────────────
  static const Color gridline = Color(0xFFE9EFF1);
  static const Color axisText = AppColors.textTertiary;
  static const Color tooltipBackground = AppColors.secondary;

  // ── Appointment status slots (validated set) ────────────
  static const Color statusCompleted = Color(0xFF0CA30C);
  static const Color statusConfirmed = Color(0xFF2A78D6);
  static const Color statusPending = Color(0xFFEDA100);
  static const Color statusCancelled = Color(0xFFD03B3B);

  /// Stacking / legend order — validated, do not reorder casually.
  static const List<String> statusOrder = [
    'completed',
    'confirmed',
    'pending',
    'cancelled',
  ];

  static Color forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return statusCompleted;
      case 'confirmed':
        return statusConfirmed;
      case 'pending':
        return statusPending;
      case 'cancelled':
        return statusCancelled;
      default:
        return deemphasis;
    }
  }

  /// Status is a state, so it never travels as colour alone — each slot ships
  /// an icon next to its label.
  static IconData iconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'confirmed':
        return Icons.event_available_outlined;
      case 'pending':
        return Icons.schedule_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
