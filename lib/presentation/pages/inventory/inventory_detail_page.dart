// lib/presentation/pages/inventory/inventory_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../../core/errors/error_message.dart';
import '../../../data/models/inventory/inventory_batch_model.dart';
import '../../../data/models/inventory/stock_movement_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/inventory/inventory_provider.dart';
import '../../providers/inventory/stock_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Everything behind one branch's stock of one item: the lots on the shelf and
/// the ledger that explains the number.
///
/// `RouteNames.inventoryDetail` has existed as a dead constant since the
/// inventory pages were written. This gives it something to point at — and it
/// is where batches and expiry become visible at all, since the list can only
/// show the earliest one.
class InventoryDetailPage extends ConsumerStatefulWidget {
  final int inventoryId;

  const InventoryDetailPage({super.key, required this.inventoryId});

  @override
  ConsumerState<InventoryDetailPage> createState() =>
      _InventoryDetailPageState();
}

class _InventoryDetailPageState extends ConsumerState<InventoryDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadById(widget.inventoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // main.dart still runs ThemeData.dark(); this page is designed light, so
    // it pins the light theme the same way the appointment and schedule pages
    // do — every state branch below paints light surfaces.
    return Theme(
      data: AppTheme.lightTheme,
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final inventory = state.selected;

    if (state.isDetailLoading && inventory == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (state.hasDetailError && inventory == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(state.detailError ?? 'Could not load this stock record.'),
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(inventoryProvider.notifier)
                    .loadById(widget.inventoryId),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (inventory == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock')),
        body: const Center(child: Text('Stock record not found.')),
      );
    }

    final key = StockKey(
      branchId: inventory.branchId,
      itemId: inventory.itemId,
    );

    final batchesAsync = ref.watch(stockBatchesProvider(key));
    final movementsAsync = ref.watch(stockMovementsProvider(key));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inventory.item?.name ?? 'Stock',
              style: AppTextStyles.titleMedium,
            ),
            Text(
              inventory.branch?.name ?? '',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          if (ref.watch(authStateProvider).hasPermission(Perm.inventoryUpdate))
            IconButton(
              tooltip: 'Edit this stock record',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.pushNamed(
                RouteNames.inventoryEdit,
                pathParameters: {'id': widget.inventoryId.toString()},
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          invalidateStock(ref, key: key);
          await ref.read(inventoryProvider.notifier).loadById(widget.inventoryId);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            _BalanceCard(
              quantity: inventory.quantity,
              unit: inventory.item?.unitOfMeasure ?? 'unit',
              isLowStock: inventory.isLowStock,
              threshold: inventory.item?.minimumThreshold,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            _sectionTitle('Lots on the shelf', Icons.inventory_2_outlined),
            const SizedBox(height: AppDimensions.paddingSmall),
            _AsyncSection<InventoryBatchModel>(
              value: batchesAsync,
              emptyMessage: 'No open lots. Receiving stock creates one.',
              onRetry: () => ref.invalidate(stockBatchesProvider(key)),
              itemBuilder: (batch) => _BatchTile(batch: batch),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),
            _sectionTitle('History', Icons.history),
            const SizedBox(height: AppDimensions.paddingSmall),
            _AsyncSection<StockMovementModel>(
              value: movementsAsync,
              emptyMessage: 'Nothing recorded yet.',
              onRetry: () => ref.invalidate(stockMovementsProvider(key)),
              itemBuilder: (movement) => _MovementTile(movement: movement),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryDark),
        const SizedBox(width: AppDimensions.paddingSmall),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// BALANCE
// ─────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final int quantity;
  final String unit;
  final bool isLowStock;
  final int? threshold;

  const _BalanceCard({
    required this.quantity,
    required this.unit,
    required this.isLowStock,
    this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    // Negative means supplies were used that nobody had recorded — a
    // reconciliation someone still owes, and more serious than merely low.
    final isNegative = quantity < 0;

    final color = isNegative
        ? AppColors.error
        : isLowStock
            ? AppColors.warning
            : AppColors.success;

    final label = isNegative
        ? 'Over-used — more was recorded than was in stock'
        : isLowStock
            ? 'At or below the reorder point'
            : 'In stock';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isNegative
                ? Icons.error_outline
                : isLowStock
                    ? Icons.trending_down
                    : Icons.check_circle_outline,
            color: color,
            size: 32,
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$quantity ${quantity.abs() == 1 ? unit : '${unit}s'}',
                  style: AppTextStyles.titleLarge.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  threshold == null ? label : '$label · reorder at $threshold',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ASYNC SECTION
// ─────────────────────────────────────────────────────────
class _AsyncSection<T> extends StatelessWidget {
  final AsyncValue<List<T>> value;
  final String emptyMessage;
  final VoidCallback onRetry;
  final Widget Function(T) itemBuilder;

  const _AsyncSection({
    required this.value,
    required this.emptyMessage,
    required this.onRetry,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              describeError(e),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          // A 403 is settled server-side; retrying only repeats it.
          if (!isPermissionError(e))
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMedium,
            ),
            child: Text(
              emptyMessage,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          );
        }

        return Column(children: rows.map(itemBuilder).toList());
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// BATCH
// ─────────────────────────────────────────────────────────
class _BatchTile extends StatelessWidget {
  final InventoryBatchModel batch;

  const _BatchTile({required this.batch});

  @override
  Widget build(BuildContext context) {
    final expired = batch.isExpired || (batch.daysUntilExpiry ?? 1) < 0;
    final expiringSoon = batch.isExpiringWithin(30);

    final color = expired
        ? AppColors.error
        : expiringSoon
            ? AppColors.warning
            : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: expired || expiringSoon
              ? color.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.lotLabel,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Icon as well as colour — state is never encoded by
                    // colour alone.
                    Icon(
                      expired
                          ? Icons.error_outline
                          : expiringSoon
                              ? Icons.schedule_outlined
                              : Icons.event_available_outlined,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      batch.expiryLabel,
                      style: AppTextStyles.bodySmall.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            batch.amountLabel,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MOVEMENT
// ─────────────────────────────────────────────────────────
class _MovementTile extends StatelessWidget {
  final StockMovementModel movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final color = movement.isShortfall
        ? AppColors.error
        : movement.isInflow
            ? AppColors.success
            : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              movement.deltaLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      movement.typeLabel,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (movement.isShortfall) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: AppColors.error),
                      const SizedBox(width: 3),
                      Text(
                        'no stock',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
                if (movement.reason != null && movement.reason!.isNotEmpty)
                  Text(
                    movement.reason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                Text(
                  [
                    movement.actorLabel,
                    if (movement.lotNumber != null) 'lot ${movement.lotNumber}',
                  ].join(' · '),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          // The running balance is what makes this read as a statement rather
          // than a list of edits.
          Text(
            '${movement.balanceAfter}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
