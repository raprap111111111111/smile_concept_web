import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/notification/notification_model.dart';
import '../../providers/notification/notification_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({
    super.key,
  });

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final GlobalKey _buttonKey = GlobalKey();

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
      color: AppColors.surfaceDark,
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
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
            child: _NotificationDropdownContent(
              parentContext: context,
            ),
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
        IconButton(
          tooltip: 'Notifications',
          onPressed: _openDropdown,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white.withValues(alpha: 0.82),
            size: 25,
          ),
        ),
        if (hasUnread)
          Positioned(
            right: 7,
            top: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.surfaceDark,
                  width: 1.5,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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

class _NotificationDropdownContent extends ConsumerWidget {
  final BuildContext parentContext;

  const _NotificationDropdownContent({
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListProvider);
    final notifier = ref.read(notificationListProvider.notifier);

    final latest = state.notifications.take(5).toList();

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 480,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, ref, notifier),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          else if (latest.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 34,
                horizontal: 20,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: latest.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
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

                      _showNotificationDetails(
                        parentContext,
                        notification,
                      );
                    },
                  );
                },
              ),
            ),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

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
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await notifier.markAllAsRead();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        parentContext.goNamed(RouteNames.notifications);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'View all notifications',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                _iconFor(notification.icon),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            notification.message.isEmpty
                ? 'No message content.'
                : notification.message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
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

class _DropdownNotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _DropdownNotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: unread
                  ? AppColors.primary.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.06),
              child: Icon(
                _iconFor(notification.icon),
                size: 18,
                color: unread
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          unread ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 12,
                      height: 1.25,
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
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
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