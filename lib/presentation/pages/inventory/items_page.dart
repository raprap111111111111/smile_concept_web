// lib/presentation/pages/inventory/items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../data/models/inventory/item_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/inventory/item_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import '../../widgets/shared/search_bar_onclick.dart';

class ItemsPage extends ConsumerStatefulWidget {
  const ItemsPage({super.key});

  @override
  ConsumerState<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends ConsumerState<ItemsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemProvider.notifier).loadItems();
    });

    // Same 200px trigger as InventoryPage, so the two lists behave alike.
    _scrollController.addListener(() {
      final position = _scrollController.position;

      if (position.pixels >= position.maxScrollExtent - 200) {
        ref.read(itemProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) =>
      ref.read(itemProvider.notifier).loadItems(search: query);

  void _onClearSearch() {
    _searchController.clear();
    ref.read(itemProvider.notifier).loadItems(search: '');
  }

  Future<void> _delete(int id, String name) async {
    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Item',
      itemName: name,
      description: 'You are about to delete "$name" from the item catalog. '
          'This is refused while any branch still holds stock of it.',
    );

    if (!confirmed || !mounted) return;

    final success = await ref.read(itemProvider.notifier).deleteItem(id);

    if (!mounted) return;

    if (success) {
      ToastHelper.success(context, '"$name" deleted from catalog');
    } else {
      // The server refuses with a 409 naming how many branches still stock it,
      // which is far more useful than a flat "failed to delete".
      ToastHelper.error(
        context,
        ref.read(itemProvider).submitError ?? 'Could not delete "$name".',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemProvider);
    final auth = ref.watch(authStateProvider);
    // Either family grants the catalog, matching the router's /items rule.
    final canCreate = auth.hasAnyPermission(
      [Perm.itemCreate, Perm.inventoryCreate],
    );
    final canDelete = auth.hasAnyPermission(
      [Perm.itemDelete, Perm.inventoryDelete],
    );

    // main.dart still runs ThemeData.dark(); this page is designed light, so
    // it pins the light theme the same way the appointment and schedule pages
    // do — otherwise the search field and dialogs inherit dark defaults.
    return Theme(
      data: AppTheme.lightTheme,
      child: _buildScaffold(state, canCreate, canDelete),
    );
  }

  Widget _buildScaffold(ItemState state, bool canCreate, bool canDelete) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: _ItemsHeader(
                  canCreate: canCreate,
                  onCreate: () => context.pushNamed(RouteNames.itemCreate),
                  onRefresh: () => ref.read(itemProvider.notifier).refresh(),
                ),
              ),
            ),
          ),

          // ── Search ───────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingLarge,
                  0,
                  AppDimensions.paddingLarge,
                  AppDimensions.paddingMedium,
                ),
                child: SearchBarOnClick(
                  controller: _searchController,
                  hintText: 'Search by name, SKU or category...',
                  onChanged: _onSearch,
                  onClear: _onClearSearch,
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────
          Expanded(child: _buildBody(state, canDelete)),
        ],
      ),
    );
  }

  Widget _buildBody(ItemState state, bool canDelete) {
    if (state.isListLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.hasListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(state.listError ?? 'Error', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton.icon(
              onPressed: () => ref.read(itemProvider.notifier).refresh(),
              icon:
                  const Icon(Icons.refresh, size: AppDimensions.iconSizeSmall),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentWithOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services_outlined,
                  size: 56, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text('No items yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              'Add items like gloves, dental cement, syringes, etc.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(itemProvider.notifier).refresh(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLarge,
              0,
              AppDimensions.paddingLarge,
              AppDimensions.paddingLarge,
            ),
            // Trailing spinner row while the next page loads, matching
            // InventoryPage.
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final item = state.items[index];

              return _ItemCard(
                item: item,
                canDelete: canDelete,
                onDelete: () => _delete(item.id, item.name),
                // The edit route has existed all along but nothing linked to
                // it — it was reachable only by typing the URL.
                onTap: () => context.pushNamed(
                  RouteNames.itemEdit,
                  pathParameters: {'id': item.id.toString()},
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  /// Typed, not `dynamic` — this card reads five fields off it and had no
  /// compile-time safety on any of them.
  final ItemModel item;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _ItemCard({
    required this.item,
    this.canDelete = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      // Material + InkWell rather than a bare GestureDetector, so the tap has
      // a ripple and the card reads as actionable.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.cardPaddingSmall),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.iconBadgeSize,
                  height: AppDimensions.iconBadgeSize,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: AppDimensions.iconSizeMedium),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.titleSmall),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip(item.sku, AppColors.primaryDark),
                          _chip(item.category, AppColors.primary),
                          _chip(item.unitOfMeasure, AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Min. threshold: ${item.minimumThreshold}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.actionDeleteInk,
                    iconSize: AppDimensions.iconSizeMedium,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  final bool canCreate;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  const _ItemsHeader({
    required this.canCreate,
    required this.onCreate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap sizes itself to its content under the loose constraints it gets
    // here, which leaves spaceBetween nothing to distribute — the title and
    // the actions ended up packed together on the left. Forcing full width
    // gives the alignment its free space while keeping the wrap-to-next-line
    // behaviour on narrow screens.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: AppDimensions.paddingMedium,
        runSpacing: AppDimensions.paddingMedium,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppDimensions.iconBadgeSize,
                height: AppDimensions.iconBadgeSize,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryWithOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: Colors.white,
                  size: AppDimensions.iconSize,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Catalog', style: AppTextStyles.titleLarge),
                  Text(
                    'Manage consumable items and supplies',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: AppDimensions.paddingXS,
            runSpacing: AppDimensions.paddingXS,
            children: [
              _HeaderIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: onRefresh,
              ),
              if (canCreate)
                _HeaderActionButton(
                  icon: Icons.add,
                  label: 'New Item',
                  onPressed: onCreate,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryWithOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: AppDimensions.iconSizeSmall,
                ),
                const SizedBox(width: AppDimensions.paddingXS),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.primaryDark,
          size: AppDimensions.iconSizeMedium,
        ),
        tooltip: tooltip,
      ),
    );
  }
}
