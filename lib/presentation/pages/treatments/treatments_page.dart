// lib/presentation/pages/treatments/treatments_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/treatment/treatment_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shared/search_bar_onclick.dart';
import 'widgets/treatment_card.dart';
import 'widgets/treatment_empty_state.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';

class TreatmentsPage extends ConsumerStatefulWidget {
  const TreatmentsPage({super.key});

  @override
  ConsumerState<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends ConsumerState<TreatmentsPage> {
  final _scrollController = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load({bool forceRefresh = false}) {
    ref
        .read(treatmentProvider.notifier)
        .loadTreatments(forceRefresh: forceRefresh);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(treatmentProvider.notifier).loadMore();
    }
  }

  // ── Filter ──
  List<dynamic> _filterTreatments(List<dynamic> treatments) {
    if (_search.isEmpty) return treatments;
    final query = _search.toLowerCase();
    return treatments.where((t) {
      final name = t.name.toString().toLowerCase();
      final description = (t.description ?? '').toString().toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  // ── Delete ──
  Future<void> _delete(int id, String name) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.treatmentDelete)) {
      _showSnack('No permission to delete treatments', AppColors.error);
      return;
    }

    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Treatment',
      itemName: name,
      description:
          'You are about to delete "$name" from the treatments catalog. '
          'Existing patient records referencing this treatment will remain, '
          'but it will no longer be available for new procedures. '
          'This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    final success =
        await ref.read(treatmentProvider.notifier).deleteTreatment(id);

    if (!mounted) return;
    _showSnack(
      success
          ? '"$name" deleted from catalog'
          : ref.read(treatmentProvider).listError ?? 'Failed to delete',
      success ? AppColors.success : AppColors.error,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentProvider);
    final auth = ref.watch(authStateProvider);

    final canCreate = auth.hasPermission(Perm.treatmentCreate);
    final canDelete = auth.hasPermission(Perm.treatmentDelete);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.paddingMedium,
              right: AppDimensions.paddingMedium,
              top: AppDimensions.paddingMedium,
            ),
            child: SearchBarOnClick(
              hintText: 'Search treatments...',
              onChanged: (v) => setState(() => _search = v),
              onClear: () => setState(() => _search = ''),
            ),
          ),
          Expanded(child: _buildBody(state, canDelete)),
        ],
      ),
      floatingActionButton: canCreate ? _buildFAB() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.divider,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Treatments Catalog', style: AppTextStyles.titleLarge),
          Text(
            'Manage your treatment offerings',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onPressed: () => _load(forceRefresh: true),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.pushNamed(RouteNames.treatmentCreate),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 2,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'New Treatment',
        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildBody(TreatmentState state, bool canDelete) {
    if (state.isListLoading) {
      return const _LoadingView();
    }

    if (state.hasListError) {
      return _ErrorView(
        message: state.listError ?? 'Something went wrong',
        onRetry: () => _load(forceRefresh: true),
      );
    }

    if (state.isEmpty) {
      return TreatmentEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    final filtered = _filterTreatments(state.treatments);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No treatments match "$_search"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.background,
      onRefresh: () => ref.read(treatmentProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            return const _LoadMoreIndicator();
          }
          final t = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
            child: TreatmentCard(
              treatment: t,
              canDelete: canDelete,
              onDelete: () => _delete(t.id, t.name),
            ),
          );
        },
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          width: AppDimensions.iconBadgeSize,
          height: AppDimensions.iconBadgeSize,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconSize,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Loading treatments...',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusLarge,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: AppDimensions.iconSizeSmall,
              ),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppDimensions.paddingLarge),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              'Loading more...',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}