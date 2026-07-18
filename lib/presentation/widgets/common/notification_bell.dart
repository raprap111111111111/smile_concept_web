// lib/presentation/widgets/common/notification_bell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/notification/notification_model.dart';
import '../../providers/notification/notification_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isHovering = false;

  Future<void> _openDropdown() async {
    await ref.read(notificationListProvider.notifier).load();

    if (!mounted) return;

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    await showMenu(
      context: context,
      // ── CHANGED: Light theme background ────────────────
      color: AppColors.background,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx - 360 + size.width,
        offset.dy + size.height + 8,
        offset.dx,
        0,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 380,
            child: _NotificationDropdownContent(parentContext: context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(unreadNotificationCountProvider);

    final unreadCount = countAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final hasUnread = unreadCount > 0;

    return Stack(
      key: _buttonKey,
      clipBehavior: Clip.none,
      children: [
        // ── Button Container ─────────────────────────────────
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isHovering
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: _openDropdown,
                splashRadius: 22,
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
            ),
          ),
        ),

        // ── Badge ────────────────────────────────────────────
        if (hasUnread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Dropdown Content ─────────────────────────────────────────
class _NotificationDropdownContent extends ConsumerWidget {
  final BuildContext parentContext;

  const _NotificationDropdownContent({required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListProvider);
    final notifier = ref.read(notificationListProvider.notifier);

    final latest = state.notifications.take(5).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, ref, notifier),
          const Divider(height: 1, color: AppColors.divider),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            )
          else if (latest.isEmpty)
            const _EmptyState()
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: latest.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final notification = latest[index];
                  return _DropdownNotificationItem(
                    notification: notification,
                    onTap: () async {
                      Navigator.pop(context);
                      if (notification.isUnread) {
                        await notifier.markAsRead(notification.id);
                      }
                      if (!parentContext.mounted) return;
                      _showNotificationDetails(parentContext, notification);
                    },
                  );
                },
              ),
            ),
          const Divider(height: 1, color: AppColors.divider),
          _buildFooter(context),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    NotificationListNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await notifier.markAllAsRead();
            },
            icon: const Icon(
              Icons.done_all_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            label: const Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        parentContext.goNamed(RouteNames.notifications);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'View all notifications',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog ────────────────────────────────────────────────
  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(notification.icon),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            notification.message.isEmpty
                ? 'No message content.'
                : notification.message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
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

// ── Empty State ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.textTertiary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "We'll notify you when something arrives",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Item ────────────────────────────────────────
class _DropdownNotificationItem extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _DropdownNotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  State<_DropdownNotificationItem> createState() =>
      _DropdownNotificationItemState();
}

class _DropdownNotificationItemState
    extends State<_DropdownNotificationItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final unread = widget.notification.isUnread;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _isHovering
              ? AppColors.primary.withValues(alpha: 0.06)
              : unread
                  ? AppColors.accentLight
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: unread
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: unread
                        ? AppColors.primary.withValues(alpha: 0.20)
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  _iconFor(widget.notification.icon),
                  size: 18,
                  color:
                      unread ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight:
                            unread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
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