// lib/presentation/pages/doctor_schedules/widgets/schedule_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/doctor_schedule/doctor_schedule_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ScheduleCard extends StatelessWidget {
  final DoctorScheduleModel schedule;

  /// Null hides the button — the caller passes null when the signed-in role
  /// lacks `doctor-schedule.update` / `.delete`.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onDelete,
  });

  /// `"14:30:00"` → `"2:30 PM"`. The API sends 24-hour `HH:mm[:ss]`; anything
  /// that doesn't parse is shown as-is rather than swallowed.
  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return time;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return time;

    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
  }

  /// Get color based on day of week for visual variety
  Color _getDayColor() {
    switch (schedule.dayOfWeek) {
      case 0: // Sunday
        return const Color(0xFFEF4444); // red
      case 1: // Monday
        return AppColors.primary;
      case 2: // Tuesday
        return const Color(0xFF8B5CF6); // purple
      case 3: // Wednesday
        return const Color(0xFF10B981); // emerald
      case 4: // Thursday
        return const Color(0xFFF59E0B); // amber
      case 5: // Friday
        return const Color(0xFF3B82F6); // blue
      case 6: // Saturday
        return const Color(0xFFEC4899); // pink
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayColor = _getDayColor();
    final doctor = schedule.doctor;
    final branch = schedule.branch;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Left accent bar ──────────────────────────────
          Container(
            width: 4,
            height: 130,
            decoration: BoxDecoration(
              color: dayColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
                bottomLeft: Radius.circular(AppDimensions.borderRadiusLarge),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top row: Day badge + Actions ─────────
                  Row(
                    children: [
                      // Day badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: dayColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          schedule.dayLabel,
                          style: TextStyle(
                            color: dayColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(width: AppDimensions.paddingSmall),

                      // Time chip
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_formatTime(schedule.startTime)} – ${_formatTime(schedule.endTime)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Action buttons
                      if (onEdit != null) ...[
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.primary,
                          tooltip: 'Edit',
                          onTap: onEdit!,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (onDelete != null)
                        _ActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          tooltip: 'Delete',
                          onTap: onDelete!,
                        ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.paddingSmall),

                  // ── Doctor Info ───────────────────────────
                  if (doctor != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(doctor.profile.name),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Name & specialty
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Dr. ${doctor.profile.name}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doctor.specialty,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                  ],

                  // ── Branch info ─────────────────────────
                  if (branch != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${branch.name}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              branch.branchCode,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Extract initials from a name (e.g., "Sarah Chen" → "SC")
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────
// REUSABLE: Action Button
// ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}