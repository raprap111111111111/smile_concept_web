import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification/notification_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/notification_tile.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final notifier = ref.read(notificationListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(notifier),
            const SizedBox(height: 20),
            _buildFilters(notifier),
            const SizedBox(height: 20),
            Expanded(
              child: _buildBody(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationListNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF4F46E5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Click a notification to view details and mark it as read',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: notifier.markAllAsRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Refresh',
              onPressed: notifier.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(NotificationListNotifier notifier) {
    return Row(
      children: [
        FilterChip(
          label: const Text('All'),
          selected: !_unreadOnly,
          onSelected: (_) {
            setState(() => _unreadOnly = false);
            notifier.load(unreadOnly: false);
          },
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Unread'),
          selected: _unreadOnly,
          onSelected: (_) {
            setState(() => _unreadOnly = true);
            notifier.load(unreadOnly: true);
          },
        ),
      ],
    );
  }

  Widget _buildBody(
    NotificationListState state,
    NotificationListNotifier notifier,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications found',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];

          return NotificationTile(
            notification: notification,
            onTap: () async {
              if (notification.isUnread) {
                await notifier.markAsRead(notification.id);
              }

              if (!mounted) return;

              _showNotificationDetails(notification.title, notification.message);
            },
            onDelete: () => notifier.deleteNotification(notification.id),
          );
        },
      ),
    );
  }

  void _showNotificationDetails(String title, String message) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message.isEmpty ? 'No message content.' : message,
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
}