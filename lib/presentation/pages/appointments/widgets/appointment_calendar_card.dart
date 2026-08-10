// lib/presentation/pages/appointments/widgets/appointment_calendar_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment/appointment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'appointment_status_badge.dart';

/// One appointment row in the day list: time, patient, doctor, branch, status.
///
/// Every colour here is pinned to [AppColors]. The app still boots on
/// `ThemeData.dark()`, so an unstyled `Card`/`Text` inherits a dark surface and
/// white text and lands as a dark block on this light page.
class AppointmentCalendarCard extends StatelessWidget {
  final AppointmentModel appointment;
  final int? currentUserId;
  final bool canViewAll;
  final bool canUpdateStatus;

  /// Cancel-only badge menu for patients without update-status.
  final bool canCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onCancel;

  const AppointmentCalendarCard({
    super.key,
    required this.appointment,
    this.currentUserId,
    this.canViewAll = false,
    this.canUpdateStatus = false,
    this.canCancel = false,
    this.onEdit,
    this.onDelete,
    this.onStatusChanged,
    this.onCancel,
  });

  /// Below this the time block moves above the details instead of beside them.
  static const double _compactBreakpoint = 520;

  bool get isOwnAppointment => appointment.userId == currentUserId;

  String _formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  String get _durationLabel {
    final minutes =
        appointment.endTime.difference(appointment.startTime).inMinutes;
    if (minutes <= 0) return '—';
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppointmentStatusPalette.of(appointment.status);
    final reason = appointment.cancellationReason?.trim();
    final showReason = appointment.status == AppointmentStatus.cancelled &&
        reason != null &&
        reason.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _compactBreakpoint;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status rail — a second, redundant read of the badge below.
                Container(width: 5, color: palette.ink),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppDimensions.paddingMedium),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimeRow(),
                              const SizedBox(
                                height: AppDimensions.paddingSmall,
                              ),
                              _buildDetails(showReason: showReason,
                                  reason: reason),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 96, child: _buildTimeColumn()),
                              const SizedBox(
                                width: AppDimensions.paddingMedium,
                              ),
                              Expanded(
                                child: _buildDetails(
                                  showReason: showReason,
                                  reason: reason,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TIME ───────────────────────────────────────────────────
  Widget _buildTimeColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(appointment.startTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatTime(appointment.endTime),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        _DurationPill(label: _durationLabel),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          _formatTime(appointment.startTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: AppColors.ink,
          ),
        ),
        Text(
          '– ${_formatTime(appointment.endTime)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        _DurationPill(label: _durationLabel),
      ],
    );
  }

  // ── DETAILS ────────────────────────────────────────────────
  Widget _buildDetails({required bool showReason, String? reason}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      appointment.user?.name ?? 'Unknown Patient',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                    if (canViewAll && isOwnAppointment) const _YoursChip(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingXS),
            AppointmentStatusBadge(
              status: appointment.status,
              canUpdate: canUpdateStatus,
              canCancel: canCancel,
              onStatusChanged: onStatusChanged,
              onCancel: onCancel,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Wrap(
          spacing: AppDimensions.paddingMedium,
          runSpacing: 6,
          children: [
            _MetaItem(
              icon: Icons.medical_services_outlined,
              value: appointment.doctor?.name,
              emptyLabel: 'No doctor assigned',
            ),
            _MetaItem(
              icon: Icons.location_on_outlined,
              value: appointment.branch?.name,
              emptyLabel: 'No branch',
            ),
          ],
        ),
        if (showReason) ...[
          const SizedBox(height: AppDimensions.paddingSmall),
          _ReasonStrip(reason: reason!),
        ],
        if (onEdit != null || onDelete != null) ...[
          const SizedBox(height: AppDimensions.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null)
                _CardAction(
                  tooltip: 'Reschedule',
                  icon: Icons.edit_calendar_outlined,
                  color: AppColors.primaryDark,
                  onTap: onEdit!,
                ),
              if (onEdit != null && onDelete != null)
                const SizedBox(width: AppDimensions.paddingXS),
              if (onDelete != null)
                _CardAction(
                  tooltip: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.statusCancelledInk,
                  onTap: onDelete!,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Card parts ──────────────────────────────────────────────

class _DurationPill extends StatelessWidget {
  final String label;

  const _DurationPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _YoursChip extends StatelessWidget {
  const _YoursChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'YOURS',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          height: 1.4,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String? value;
  final String emptyLabel;

  const _MetaItem({
    required this.icon,
    required this.value,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    final isEmpty = text == null || text.isEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            isEmpty ? emptyLabel : text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w600,
              height: 1.3,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              color:
                  isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonStrip extends StatelessWidget {
  final String reason;

  const _ReasonStrip({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledSoft,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: AppColors.statusCancelledInk.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.statusCancelledInk,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.statusCancelledInk,
                ),
                children: [
                  const TextSpan(
                    text: 'Reason: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      side: const BorderSide(color: AppColors.border),
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          hoverColor: color.withValues(alpha: 0.10),
          focusColor: color.withValues(alpha: 0.16),
          splashColor: color.withValues(alpha: 0.14),
          // 44x44: the minimum comfortable touch target, and close enough to
          // the 42px header tiles to read as the same control family.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
