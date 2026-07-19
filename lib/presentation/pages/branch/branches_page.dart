import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/branch/branch_model.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../providers/branch/branch_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/branch_card.dart';
import 'widgets/branch_filters.dart';
import 'widgets/branch_form_dialog.dart';

class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final filter = ref.watch(branchFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BranchesHeader(
              onAdd: () => _openBranchDialog(context, ref),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            BranchFilters(
              search: filter.search,
              activeFilter: filter.isActive,
              onSearchChanged: (value) {
                ref.read(branchFilterProvider.notifier).state =
                    filter.copyWith(search: value);
              },
              onActiveFilterChanged: (value) {
                ref.read(branchFilterProvider.notifier).state = value == null
                    ? filter.copyWith(clearActive: true)
                    : filter.copyWith(isActive: value);
              },
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Expanded(
              child: branchesAsync.when(
                data: (branches) {
                  if (branches.isEmpty) {
                    return const BranchesEmptyState();
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisSpacing: AppDimensions.paddingMedium,
                      crossAxisSpacing: AppDimensions.paddingMedium,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];

                      return BranchCard(
                        branch: branch,
                        onEdit: () => _openBranchDialog(
                          context,
                          ref,
                          branch: branch,
                        ),
                        onDelete: () => _confirmDelete(
                          context,
                          ref,
                          branch,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error: $error',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openBranchDialog(
    BuildContext context,
    WidgetRef ref, {
    BranchModel? branch,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BranchFormDialog(branch: branch),
    );

    if (result == null || !context.mounted) return;

    final repository = ref.read(branchRepositoryProvider);
    final isEdit = branch != null;

    try {
      if (isEdit) {
        await repository.updateBranch(branch.id, result);
      } else {
        await repository.createBranch(result);
      }

      ref.invalidate(branchesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            isEdit ? 'Branch updated' : 'Branch created',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Error: $error',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BranchModel branch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Delete Branch',
          style: AppTextStyles.titleMedium,
        ),
        content: Text(
          "Are you sure you want to delete '${branch.name}'?",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(branchRepositoryProvider).deleteBranch(branch.id);

      ref.invalidate(branchesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Branch deleted',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Error: $error',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }
}

class BranchesHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const BranchesHeader({
    super.key,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.business_outlined,
                color: Colors.white,
                size: AppDimensions.iconBadgeSize * 0.6,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branches',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your clinic locations',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: AppDimensions.iconSize,
                    ),
                    const SizedBox(width: AppDimensions.paddingXS),
                    Text(
                      'Add Branch',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BranchesEmptyState extends StatelessWidget {
  const BranchesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No branches found',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'Add a branch to get started',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}