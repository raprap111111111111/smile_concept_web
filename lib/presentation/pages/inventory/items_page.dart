// lib/presentation/pages/inventory/items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/presentation/constant/permission_constants.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/inventory/item_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class ItemsPage extends ConsumerStatefulWidget {
  const ItemsPage({super.key});

  @override
  ConsumerState<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends ConsumerState<ItemsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemProvider.notifier).loadItems();
    });
  }

  Future<void> _delete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: const Text('Delete Item?', style: AppTextStyles.titleMedium),
        content: Text('Delete "$name"? This cannot be undone.',
            style: AppTextStyles.bodyMedium),
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

    final success =
        await ref.read(itemProvider.notifier).deleteItem(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Item deleted' : 'Failed to delete',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemProvider);
    final auth = ref.watch(authStateProvider);
    final canCreate = auth.hasPermission(Perm.inventoryCreate);
    final canDelete = auth.hasPermission(Perm.inventoryDelete);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.iconBadgeSize,
                  height: AppDimensions.iconBadgeSize,
                  decoration: BoxDecoration(
                    color: AppColors.accentWithOpacity(0.18),
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.primaryDark,
                    size: AppDimensions.iconSize,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Items Catalog',
                          style: AppTextStyles.titleLarge),
                      Text(
                        'Manage consumable items and supplies',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: () => ref
                        .read(itemProvider.notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh,
                        color: AppColors.textSecondary,
                        size: AppDimensions.iconSizeMedium),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────
          Expanded(child: _buildBody(state, canDelete)),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.pushNamed(RouteNames.itemCreate),
              icon: const Icon(Icons.add,
                  size: AppDimensions.iconSizeSmall),
              label: const Text('New Item',
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
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(state.listError ?? 'Error',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(itemProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh,
                  size: AppDimensions.iconSizeSmall),
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
              padding:
                  const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.accentWithOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services_outlined,
                  size: 56, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text('No items yet',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              'Add items like gloves, dental cement, syringes, etc.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _ItemCard(
          item: item,
          canDelete: canDelete,
          onDelete: () => _delete(item.id, item.name),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _ItemCard({
    required this.item,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Row(
          children: [
            Container(
              width: AppDimensions.iconBadgeSize,
              height: AppDimensions.iconBadgeSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: const Icon(Icons.medical_services_outlined,
                  color: AppColors.primary,
                  size: AppDimensions.iconSizeMedium),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _chip(item.sku, AppColors.info),
                      const SizedBox(width: 6),
                      _chip(item.category, AppColors.primary),
                      const SizedBox(width: 6),
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
                color: AppColors.error.withOpacity(0.7),
                iconSize: AppDimensions.iconSizeMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .copyWith(color: color, fontSize: 10),
      ),
    );
  }
}