// lib/presentation/pages/notifications/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
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
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(notifier),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildFilters(notifier),
            const SizedBox(height: AppDimensions.paddingLarge),
            Expanded(
              child: _buildBody(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationListNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left title area ───────────────────────────────
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textOnPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click a notification to view details and mark it as read',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Actions ───────────────────────────────────────
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => notifier.markAllAsRead(),
                icon: const Icon(
                  Icons.done_all_rounded,
                  size: AppDimensions.iconSizeSmall,
                ),
                label: const Text('Mark all read'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: AppDimensions.paddingSmall,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  tooltip: 'Refresh',
                  onPressed: notifier.refresh,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(NotificationListNotifier notifier) {
    return Row(
      children: [
        FilterChip(
          label: const Text('All'),
          selected: !_unreadOnly,
          checkmarkColor: AppColors.textOnPrimary,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.background,
          side: const BorderSide(color: AppColors.border),
          labelStyle: TextStyle(
            color: !_unreadOnly ? AppColors.textOnPrimary : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
          avatar: !_unreadOnly
              ? const Icon(
                  Icons.check_rounded,
                  color: AppColors.textOnPrimary,
                  size: 18,
                )
              : null,
          onSelected: (_) {
            setState(() => _unreadOnly = false);
            notifier.load(unreadOnly: false);
          },
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        FilterChip(
          label: const Text('Unread'),
          selected: _unreadOnly,
          checkmarkColor: AppColors.textOnPrimary,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.background,
          side: const BorderSide(color: AppColors.border),
          labelStyle: TextStyle(
            color: _unreadOnly ? AppColors.textOnPrimary : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
          avatar: _unreadOnly
              ? const Icon(
                  Icons.check_rounded,
                  color: AppColors.textOnPrimary,
                  size: 18,
                )
              : null,
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
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (state.error != null) {
      return _ErrorState(
        message: state.error!,
        onRetry: notifier.refresh,
      );
    }

    if (state.notifications.isEmpty) {
      return _EmptyState(
        unreadOnly: _unreadOnly,
        onRefresh: notifier.refresh,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: notifier.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];

          return NotificationTile(
            notification: notification,
            onTap: () async {
              if (notification.isUnread) {
                await notifier.markAsRead(notification.id);
              }

              if (!mounted) return;

              _showNotificationDetails(
                notification.title,
                notification.message,
              );
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
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message.isEmpty ? 'No message content.' : message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
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

class _EmptyState extends StatelessWidget {
  final bool unreadOnly;
  final Future<void> Function() onRefresh;

  const _EmptyState({
    required this.unreadOnly,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    Text(
                      unreadOnly
                          ? 'No unread notifications'
                          : 'No notifications found',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unreadOnly
                          ? 'You are all caught up.'
                          : 'New notifications will appear here.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Unable to load notifications',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}