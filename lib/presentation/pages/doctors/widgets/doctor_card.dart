// lib/presentation/pages/doctors/widgets/doctor_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import 'doctor_avatar.dart';
import 'doctor_info_row.dart';
import 'doctor_stat_chip.dart';

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final user = doctor['user'] as Map? ?? {};
    final name = user['name']?.toString() ?? '-';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '-';
    final specialization =
        doctor['specialization']?.toString() ?? 'General';
    final license = doctor['license_number']?.toString() ?? '';
    final branches = (user['branches'] as List? ?? []).cast<dynamic>();
    final isActive = user['is_active'] == true;
    final schedules = doctor['schedules_count'] ?? 0;
    final appointments = doctor['appointments_count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(name, specialization, isActive),
          const SizedBox(height: AppDimensions.paddingSmall),
          if (license.isNotEmpty) ...[
            DoctorInfoRow(
                icon: Icons.badge_outlined, text: 'License: $license'),
            const SizedBox(height: 4),
          ],
          DoctorInfoRow(icon: Icons.email_outlined, text: email),
          const SizedBox(height: 4),
          DoctorInfoRow(icon: Icons.phone_outlined, text: phone),
          if (branches.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildBranchChips(branches),
          ],
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildStats(schedules.toString(), appointments.toString()),
          const Spacer(),
          _buildActions(),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(String name, String specialization, bool isActive) {
    return Row(
      children: [
        DoctorAvatar(name: name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. $name',
                style: AppTextStyles.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                specialization,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isActive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Branch Chips ──
  Widget _buildBranchChips(List<dynamic> branches) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: branches.map((b) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            b['name']?.toString() ?? '',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryDark,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Stats Row ──
  Widget _buildStats(String schedules, String appointments) {
    return Row(
      children: [
        Expanded(
          child: DoctorStatChip(
            icon: Icons.schedule,
            value: schedules,
            label: 'Schedules',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DoctorStatChip(
            icon: Icons.event,
            value: appointments,
            label: 'Appts',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  // ── Actions ──
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadius,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}