// lib/presentation/pages/dashboard/components/schedule_card.dart
import 'package:flutter/material.dart';

import '../../../../data/models/dashboard/today_schedule.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/chart_palette.dart';
import 'charts/status_breakdown_bar.dart';

/// Today's appointments as a list, headed by the status split so the shape of
/// the day is readable before any row is.
class ScheduleCard extends StatelessWidget {
  const ScheduleCard(this.schedule, {super.key, this.onBookNew});

  final TodaySchedule schedule;
  final VoidCallback? onBookNew;

  @override
  Widget build(BuildContext context) {
    final appointments = schedule.appointments;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Schedule",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.total == 1
                          ? '1 appointment booked'
                          : '${schedule.total} appointments booked',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onBookNew,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Book New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (schedule.byStatus.isNotEmpty) ...[
            const SizedBox(height: 20),
            StatusBreakdownBar(statuses: schedule.byStatus),
          ],
          const SizedBox(height: 20),
          if (appointments.isEmpty)
            const _EmptyState(
              icon: Icons.event_busy_outlined,
              message: 'No appointments scheduled today',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.line,
                height: 20,
              ),
              itemBuilder: (context, index) =>
                  _AppointmentTile(appointments[index]),
            ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile(this.appointment);

  final ScheduleEntry appointment;

  @override
  Widget build(BuildContext context) {
    final statusColor = ChartPalette.forStatus(appointment.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.accentWithOpacity(0.22),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Text(
            appointment.time,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.patientName,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (appointment.type.isNotEmpty) appointment.type,
                  if (appointment.doctorName != null) appointment.doctorName!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Status carries an icon and a word, never colour alone.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ChartPalette.iconForStatus(appointment.status),
              size: 14,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              appointment.status.isEmpty
                  ? '—'
                  : appointment.status[0].toUpperCase() +
                      appointment.status.substring(1),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Icon(icon, color: AppColors.textTertiary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
