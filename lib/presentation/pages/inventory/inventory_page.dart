// lib/presentation/pages/inventory/inventory_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/inventory/inventory_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
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

  Future<void> _delete(int id, String? itemName) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.inventoryDelete)) {
      _showSnack('No permission to delete inventory', AppColors.error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: const Text('Delete Inventory Item?',
            style: AppTextStyles.titleMedium),
        content: Text(
          'Delete "${itemName ?? 'this item'}"? This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(inventoryProvider.notifier)
        .deleteInventory(id);

    if (!mounted) return;
    _showSnack(
      success
          ? 'Inventory item deleted'
          : ref.read(inventoryProvider).listError ?? 'Failed to delete',
      success ? AppColors.success : AppColors.error,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final auth = ref.watch(authStateProvider);

    final canCreate = auth.hasPermission(Perm.inventoryCreate);
    final canDelete = auth.hasPermission(Perm.inventoryDelete);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(state),

          // ── Search Bar ──────────────────────────────────
          _buildSearchBar(),

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
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.pushNamed(RouteNames.inventoryCreate),
              icon: const Icon(Icons.add, size: AppDimensions.iconSizeSmall),
              label: const Text('Add Stock',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge),
              ),
            )
          : null,
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
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
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
            ? AppColors.warning.withValues(alpha:0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: state.lowStockOnly
              ? AppColors.warning.withValues(alpha:0.4)
              : AppColors.border,
        ),
      ),
      child: IconButton(
        onPressed: () => ref
            .read(inventoryProvider.notifier)
            .toggleLowStockFilter(),
        icon: Icon(
          state.lowStockOnly
              ? Icons.filter_alt
              : Icons.filter_alt_outlined,
          color: state.lowStockOnly
              ? AppColors.warning
              : AppColors.textSecondary,
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

  // ── Search ──────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by item name or SKU...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: AppDimensions.iconSizeMedium,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textSecondary,
                      size: AppDimensions.iconSizeSmall),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(inventoryProvider.notifier).search('');
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
        ),
        onChanged: (value) => setState(() {}),
        onSubmitted: (value) =>
            ref.read(inventoryProvider.notifier).search(value),
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
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                state.listError ?? 'Error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton.icon(
                onPressed: () => _load(forceRefresh: true),
                icon: const Icon(Icons.refresh,
                    size: AppDimensions.iconSizeSmall),
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
      onRefresh: () =>
          ref.read(inventoryProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingXS,
        ),
        itemCount:
            state.inventories.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.inventories.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
            );
          }
          final inv = state.inventories[index];
          return InventoryCard(
            inventory: inv,
            canDelete: canDelete,
            onDelete: () => _delete(inv.id, inv.item?.name),
            onTap: () => context.pushNamed(
              RouteNames.inventoryEdit,
              pathParameters: {'id': inv.id.toString()},
            ),
          );
        },
      ),
    );
  }
}