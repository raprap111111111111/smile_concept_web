// lib/presentation/pages/notifications/widgets/notification_tile.dart

import 'package:flutter/material.dart';

import '../../../../data/models/notification/notification_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class NotificationTile extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final isUnread = notification.isUnread;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: _isHovering
                ? AppColors.primary.withValues(alpha: 0.05)
                : isUnread
                    ? AppColors.accentLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnread
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  _iconFor(notification.icon),
                  color:
                      isUnread ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMedium),

              // ── Text Content ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message.isEmpty
                          ? 'No message content.'
                          : notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMedium),

              // ── Delete Button ─────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: widget.onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? icon) {
    switch (icon) {
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'bell':
        return Icons.notifications_outlined;
      case 'check-circle':
        return Icons.check_circle_outline;
      case 'alert-triangle':
        return Icons.warning_amber_outlined;
      case 'x-circle':
        return Icons.cancel_outlined;
      case 'user-plus':
        return Icons.person_add_alt_1_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}