// lib/presentation/pages/appointments/widgets/appointment_agenda_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment/appointment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'appointment_status_badge.dart';

/// One row in a patient's agenda list: date, time, doctor/branch, status —
/// tap to open the full appointment detail page. Presentational only; the
/// parent owns navigation, mirroring [AppointmentCalendarCard]'s pattern.
class AppointmentAgendaTile extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const AppointmentAgendaTile({
    super.key,
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DateBadge(date: appointment.startTime),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateFormat('h:mm a').format(appointment.startTime)}'
                        ' – ${DateFormat('h:mm a').format(appointment.endTime)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppDimensions.paddingMedium,
                        runSpacing: 4,
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
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppointmentStatusBadge(status: appointment.status),
                    const SizedBox(height: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              height: 1.1,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            DateFormat('d').format(date),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.ink,
            ),
          ),
        ],
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
          size: 14,
          color: isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        // Flexible, not a fixed cap: on a phone the row has well under
        // 160px to give and a hard maxWidth overflows instead of eliding.
        Flexible(
          child: Text(
            isEmpty ? emptyLabel : text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w600,
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
