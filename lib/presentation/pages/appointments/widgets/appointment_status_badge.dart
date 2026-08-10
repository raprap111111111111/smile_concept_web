// lib/presentation/pages/appointments/widgets/appointment_status_badge.dart

import 'package:flutter/material.dart';

import '../../../../data/models/appointment/appointment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Light-surface tones for one appointment status.
///
/// [ink] is the only variant safe for text or icons; [accent] is decoration
/// (rails, dots) and [soft] the tint it sits on. Shared with
/// `AppointmentCalendarCard` so a status reads identically wherever it appears.
class AppointmentStatusPalette {
  final Color ink;
  final Color soft;
  final Color accent;
  final String label;
  final IconData icon;

  const AppointmentStatusPalette._({
    required this.ink,
    required this.soft,
    required this.accent,
    required this.label,
    required this.icon,
  });

  Color get border => ink.withValues(alpha: 0.22);

  static AppointmentStatusPalette of(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const AppointmentStatusPalette._(
          ink: AppColors.statusPendingInk,
          soft: AppColors.statusPendingSoft,
          accent: AppColors.statusPending,
          label: 'Pending',
          icon: Icons.schedule_rounded,
        );
      case AppointmentStatus.confirmed:
        return const AppointmentStatusPalette._(
          ink: AppColors.statusBookedInk,
          soft: AppColors.statusBookedSoft,
          accent: AppColors.statusBooked,
          label: 'Confirmed',
          icon: Icons.check_circle_outline_rounded,
        );
      case AppointmentStatus.completed:
        return const AppointmentStatusPalette._(
          ink: AppColors.statusCompletedInk,
          soft: AppColors.statusCompletedSoft,
          accent: AppColors.statusCompleted,
          label: 'Completed',
          icon: Icons.done_all_rounded,
        );
      case AppointmentStatus.cancelled:
        return const AppointmentStatusPalette._(
          ink: AppColors.statusCancelledInk,
          soft: AppColors.statusCancelledSoft,
          accent: AppColors.statusCancelled,
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
        );
    }
  }
}

class AppointmentStatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  final bool canUpdate;

  /// Cancel-only mode (patients): badge menu offers just
  /// "Cancel Appointment" — no status transitions.
  final bool canCancel;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onCancel;

  const AppointmentStatusBadge({
    super.key,
    required this.status,
    this.canUpdate = false,
    this.canCancel = false,
    this.onStatusChanged,
    this.onCancel,
  });

  /// Get next status in hierarchy
  /// Pending → Confirmed → Completed
  String? get _nextStatus {
    switch (status) {
      case AppointmentStatus.pending:
        return 'confirmed';
      case AppointmentStatus.confirmed:
        return 'completed';
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return null; // Terminal states
    }
  }

  /// Get label for next status action
  String? get _nextLabel {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Mark as Confirmed';
      case AppointmentStatus.confirmed:
        return 'Mark as Completed';
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return null;
    }
  }

  bool get _canCancel =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  @override
  Widget build(BuildContext context) {
    final isClickable = (canUpdate && (_nextStatus != null || _canCancel)) ||
        (canCancel && _canCancel);

    if (!isClickable) {
      // Just display the badge - no action available
      return _buildBadge();
    }

    // Clickable badge - shows menu on tap. The menu builds off the root
    // navigator and so misses any Theme this page wraps itself in; pin the
    // light surface and ink here or it draws as a dark popup mid-page.
    return PopupMenuButton<String>(
      tooltip: canUpdate ? 'Change status' : 'Cancel appointment',
      offset: const Offset(0, 34),
      color: AppColors.background,
      surfaceTintColor: AppColors.background,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => [
        if (canUpdate && _nextStatus != null)
          PopupMenuItem<String>(
            value: _nextStatus,
            child: _menuRow(
              icon: _iconForStatus(_nextStatus!),
              color: _inkForStatus(_nextStatus!),
              label: _nextLabel!,
            ),
          ),
        if (_canCancel)
          PopupMenuItem<String>(
            value: 'cancelled',
            child: _menuRow(
              icon: Icons.cancel_outlined,
              color: AppColors.statusCancelledInk,
              label: 'Cancel Appointment',
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'cancelled') {
          onCancel?.call();
        } else {
          onStatusChanged?.call(value);
        }
      },
      child: _buildBadge(isClickable: true),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppDimensions.paddingXS),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildBadge({bool isClickable = false}) {
    final palette = AppointmentStatusPalette.of(status);

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: isClickable ? 4 : 8,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon plus label: status never rests on colour alone.
          Icon(palette.icon, size: 13, color: palette.ink),
          const SizedBox(width: 5),
          Text(
            palette.label.toUpperCase(),
            style: TextStyle(
              color: palette.ink,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          if (isClickable)
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: palette.ink),
        ],
      ),
    );
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _inkForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusBookedInk;
      case 'completed':
        return AppColors.statusCompletedInk;
      case 'cancelled':
        return AppColors.statusCancelledInk;
      default:
        return AppColors.statusPendingInk;
    }
  }
}
