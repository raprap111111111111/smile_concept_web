// lib/presentation/pages/dashboard/components/schedule_card.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ScheduleCard extends StatelessWidget {
  final List<dynamic> appointments;

  const ScheduleCard(this.appointments, {super.key});

  @override
  Widget build(BuildContext context) {
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
            children: [
              Text(
                "Today's Schedule",
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
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
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return _AppointmentTile(
                  time: appt['time'] ?? 'N/A',
                  patientName: appt['patientName'] ?? 'Unknown Patient',
                  type: appt['type'] ?? '',
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.time,
    required this.patientName,
    required this.type,
  });

  final String time;
  final String patientName;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.accentWithOpacity(0.22),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Text(
            time,
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
                patientName,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                type,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
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
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
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