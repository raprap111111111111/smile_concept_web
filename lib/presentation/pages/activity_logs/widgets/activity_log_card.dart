// lib/presentation/pages/activity_logs/widgets/activity_log_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/activity_log/activity_log_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Single row card for the activity logs list.
class ActivityLogCard extends StatelessWidget {
  final ActivityLogModel log;
  final VoidCallback? onTap;

  const ActivityLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = _colorForAction(log.action);
    final actionIcon = _iconForAction(log.action);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon badge ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(actionIcon, color: actionColor, size: 18),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),

              // ── Main content ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action + Subject
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.displayAction,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (log.subjectLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.subjectLabel,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // User + timestamp
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            log.userName ?? 'System',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(log.createdAt),
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        if (log.ipAddress != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.wifi,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            log.ipAddress!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Chevron ─────────────────────────────────────────────────
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Color _colorForAction(String? action) {
    if (action == null) return AppColors.textSecondary;
    final a = action.toLowerCase();
    if (a.contains('create') || a.contains('add')) return AppColors.success;
    if (a.contains('delete') || a.contains('void')) return AppColors.error;
    if (a.contains('update') || a.contains('edit')) return AppColors.warning;
    if (a.contains('login') || a.contains('logout')) return AppColors.primary;
    if (a.contains('view') || a.contains('read')) return AppColors.primary;
    return AppColors.textSecondary;
  }

  IconData _iconForAction(String? action) {
    if (action == null) return Icons.circle_outlined;
    final a = action.toLowerCase();
    if (a.contains('create') || a.contains('add')) return Icons.add_circle_outline;
    if (a.contains('delete')) return Icons.delete_outline;
    if (a.contains('void')) return Icons.cancel_outlined;
    if (a.contains('update') || a.contains('edit')) return Icons.edit_outlined;
    if (a.contains('login')) return Icons.login;
    if (a.contains('logout')) return Icons.logout;
    if (a.contains('sign')) return Icons.draw_outlined;
    if (a.contains('view') || a.contains('read')) return Icons.visibility_outlined;
    if (a.contains('print') || a.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.info_outline;
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }
}