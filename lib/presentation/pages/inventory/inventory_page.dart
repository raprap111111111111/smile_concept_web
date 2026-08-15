// lib/presentation/pages/inventory/inventory_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../../core/utils/toast_helper.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/inventory/inventory_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import '../../widgets/shared/search_bar_onclick.dart';
import 'widgets/inventory_branch_filter.dart';
import 'widgets/inventory_card.dart';
import 'widgets/inventory_empty_state.dart';
import 'widgets/inventory_stats_bar.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _load({bool forceRefresh = false}) {
    ref
        .read(inventoryProvider.notifier)
        .loadInventories(forceRefresh: forceRefresh);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(inventoryProvider.notifier).loadMore();
    }
  }

  // ── Search ──
  void _onSearch(String value) {
    ref.read(inventoryProvider.notifier).search(value);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(inventoryProvider.notifier).search('');
  }

  Future<void> _delete(int id, String? itemName) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.inventoryDelete)) {
      ToastHelper.warning(context, 'You cannot delete stock records.');
      return;
    }

    final name = itemName ?? 'this item';

    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Inventory Item',
      itemName: name,
      description: 'You are about to delete "$name" from inventory. '
          'All stock records and history for this item will be permanently '
          'removed. This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    final success =
        await ref.read(inventoryProvider.notifier).deleteInventory(id);

    if (!mounted) return;

    if (success) {
      ToastHelper.success(context, '"$name" deleted from inventory');
    } else {
      ToastHelper.error(
        context,
        ref.read(inventoryProvider).listError ?? 'Could not delete "$name".',
      );
    }
  }

  /// Stock actions this user may perform, in the order they are usually needed.
  ///
  /// These four permissions have been seeded since the beginning with no code
  /// behind them; this is the first time they gate anything a user can see.
  List<({String label, IconData icon, String route})> _stockActions(
    dynamic auth,
  ) {
    return [
      if (auth.hasPermission(Perm.inventoryStockIn))
        (
          label: 'Receive stock',
          icon: Icons.add_box_outlined,
          route: RouteNames.inventoryStockIn,
        ),
      if (auth.hasPermission(Perm.inventoryStockOut))
        (
          label: 'Record usage',
          icon: Icons.remove_circle_outline,
          route: RouteNames.inventoryUsage,
        ),
      if (auth.hasPermission(Perm.inventoryAdjust))
        (
          label: 'Adjust after a count',
          icon: Icons.tune_rounded,
          route: RouteNames.inventoryAdjust,
        ),
      if (auth.hasPermission(Perm.inventoryTransfer))
        (
          label: 'Transfer between branches',
          icon: Icons.swap_horiz,
          route: RouteNames.inventoryTransfer,
        ),
      if (auth.hasPermission(Perm.inventoryCreate))
        (
          label: 'Register a new item at a branch',
          icon: Icons.playlist_add,
          route: RouteNames.inventoryCreate,
        ),
    ];
  }

  Future<void> _openStockActions(dynamic auth) async {
    final actions = _stockActions(auth);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map(
                (action) => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(action.icon, color: AppColors.primary),
                    title: Text(action.label),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.pushNamed(action.route);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final auth = ref.watch(authStateProvider);

    final canDelete = auth.hasPermission(Perm.inventoryDelete);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(state),

          // ── Search Bar (onClick) ────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: SearchBarOnClick(
              controller: _searchController,
              hintText: 'Search by item name or SKU...',
              onChanged: _onSearch,
              onClear: _onClearSearch,
            ),
          ),

          // ── Branch Filter ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLarge,
              0,
              AppDimensions.paddingLarge,
              AppDimensions.paddingSmall,
            ),
            child: InventoryBranchFilter(
              selectedBranchId: state.branchFilter,
              onChanged: (branchId) =>
                  ref.read(inventoryProvider.notifier).filterByBranch(branchId),
            ),
          ),

          // ── Stats Bar ───────────────────────────────────
          if (!state.isListLoading && state.inventories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              child: InventoryStatsBar(
                total: state.total,
                lowStock: state.lowStockCount,
                expired: state.expiredCount,
              ),
            ),

          // ── List ────────────────────────────────────────
          Expanded(child: _buildBody(state, canDelete)),
        ],
      ),
      // One entry point for every stock action rather than five competing
      // buttons. Each row is gated on its own permission, so a user only ever
      // sees what they can actually do — and the sheet is suppressed entirely
      // if that leaves nothing.
      floatingActionButton: _stockActions(auth).isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openStockActions(auth),
              icon: const Icon(Icons.bolt_outlined,
                  size: AppDimensions.iconSizeSmall),
              label: const Text(
                'Stock Actions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
            ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(InventoryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.iconBadgeSize,
            height: AppDimensions.iconBadgeSize,
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.18),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryDark,
              size: AppDimensions.iconSize,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inventory', style: AppTextStyles.titleLarge),
                const SizedBox(height: 2),
                Text(
                  'Track stock across branches',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // ── Filter Toggle ─────────────────────────
          _buildFilterButton(state),
          const SizedBox(width: AppDimensions.paddingXS),
          // ── Refresh ───────────────────────────────
          _buildRefreshButton(state.isListLoading),
        ],
      ),
    );
  }

  Widget _buildFilterButton(InventoryState state) {
    return Container(
      decoration: BoxDecoration(
        color: state.lowStockOnly
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: state.lowStockOnly
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: IconButton(
        onPressed: () =>
            ref.read(inventoryProvider.notifier).toggleLowStockFilter(),
        icon: Icon(
          state.lowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
          color:
              state.lowStockOnly ? AppColors.warning : AppColors.textSecondary,
          size: AppDimensions.iconSizeMedium,
        ),
        tooltip: state.lowStockOnly ? 'Show all' : 'Low stock only',
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: isLoading ? null : () => _load(forceRefresh: true),
        icon: isLoading
            ? SizedBox(
                width: AppDimensions.iconSizeSmall,
                height: AppDimensions.iconSizeSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(
                Icons.refresh,
                color: AppColors.textSecondary,
                size: AppDimensions.iconSizeMedium,
              ),
        tooltip: 'Refresh',
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────
  Widget _buildBody(InventoryState state, bool canDelete) {
    if (state.isListLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasListError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                state.listError ?? 'Error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton.icon(
                onPressed: () => _load(forceRefresh: true),
                icon: const Icon(
                  Icons.refresh,
                  size: AppDimensions.iconSizeSmall,
                ),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return InventoryEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingXS,
        ),
        itemCount: state.inventories.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.inventories.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final inv = state.inventories[index];
          return InventoryCard(
            inventory: inv,
            canDelete: canDelete,
            onDelete: () => _delete(inv.id, inv.item?.name),
            // Detail rather than edit: the lots and the history are what a
            // reader actually wants from a stock row, and the summary line
            // can only ever show the earliest expiry. Editing is reachable
            // from there.
            onTap: () => context.pushNamed(
              RouteNames.inventoryDetail,
              pathParameters: {'id': inv.id.toString()},
            ),
          );
        },
      ),
    );
  }
}