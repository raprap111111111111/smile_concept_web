import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class DoctorStatsSection extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorStatsSection({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final schedules = (doctor['schedules_count'] ?? 0).toString();
    final appointments = (doctor['appointments_count'] ?? 0).toString();
    final patients = (doctor['patients_count'] ?? 0).toString();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            value: schedules,
            label: 'Schedules',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.event,
            value: appointments,
            label: 'Appointments',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.people_outline,
            value: patients,
            label: 'Patients',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}