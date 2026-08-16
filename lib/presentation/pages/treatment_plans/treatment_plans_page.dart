// lib/presentation/pages/treatment_plans/treatment_plans_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '/presentation/providers/treatment/treatment_plan_provider.dart';
import '../../../data/models/treatment/treatment_plan_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import 'widgets/record_supplies_dialog.dart';
import 'widgets/status_change_dialog.dart';
import 'widgets/treatment_plan_card.dart';
import 'widgets/treatment_plan_empty_state.dart';

class TreatmentPlansPage extends ConsumerStatefulWidget {
  final int? patientId;
  final int? doctorId;

  const TreatmentPlansPage({
    super.key,
    this.patientId,
    this.doctorId,
  });

  @override
  ConsumerState<TreatmentPlansPage> createState() => _TreatmentPlansPageState();
}

class _TreatmentPlansPageState extends ConsumerState<TreatmentPlansPage> {
  final _scrollController = ScrollController();
  String? _selectedStatus;

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
    ref.read(treatmentPlanProvider.notifier).loadPlans(
          patientId: widget.patientId,
          doctorId: widget.doctorId,
          status: _selectedStatus,
          forceRefresh: forceRefresh,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(treatmentPlanProvider.notifier).loadMore();
    }
  }

  Future<void> _delete(int id, String name) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.treatmentPlanDelete)) {
      _showSnack('No permission to delete treatment plans', AppColors.error);
      return;
    }

    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Treatment Plan',
      itemName: name,
      description: 'You are about to permanently delete "$name". '
          'All plan items and history associated with this plan will be '
          'removed. This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    final success =
        await ref.read(treatmentPlanProvider.notifier).deletePlan(id);

    if (!mounted) return;
    _showSnack(
      success
          ? '"$name" deleted successfully'
          : ref.read(treatmentPlanProvider).listError ?? 'Failed to delete',
      success ? AppColors.success : AppColors.error,
    );
  }

  Future<void> _changeStatus(TreatmentPlanModel plan) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.treatmentPlanUpdate)) {
      _showSnack('No permission to change status', AppColors.error);
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatusChangeDialog(currentStatus: plan.status),
    );

    if (result == null || !mounted) return;

    final error = await ref.read(treatmentPlanProvider.notifier).changeStatus(
          id: plan.id,
          status: result['status']!,
          reason: result['reason'],
        );

    if (!mounted) return;

    if (error != null) {
      _load(forceRefresh: true);
      _showSnack(error, AppColors.error);
      return;
    }

    _showSnack('Status changed to ${result['status']}', AppColors.success);

    // Completing the plan is the moment staff still remember what was used, so
    // offer the recording right here rather than making them find the card
    // again.
    if (result['status'] == 'completed' &&
        auth.hasPermission(Perm.treatmentPlanRecordConsumables)) {
      await RecordSuppliesDialog.show(context, plan);
      if (!mounted) return;
    }

    _load(forceRefresh: true);
  }

  Future<void> _recordSupplies(TreatmentPlanModel plan) async {
    final recorded = await RecordSuppliesDialog.show(context, plan);

    if (recorded == true && mounted) {
      _load(forceRefresh: true);
    }
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
    final state = ref.watch(treatmentPlanProvider);
    final auth = ref.watch(authStateProvider);
    final canCreate = auth.hasPermission(Perm.treatmentPlanCreate);
    final canDelete = auth.hasPermission(Perm.treatmentPlanDelete);
    final canChangeStatus = auth.hasPermission(Perm.treatmentPlanUpdate);
    final canRecordSupplies =
        auth.hasPermission(Perm.treatmentPlanRecordConsumables);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _PageHeader(onRefresh: () => _load(forceRefresh: true)),
          _PlanFilterBar(
            selectedStatus: _selectedStatus,
            counts: _buildCounts(state),
            onStatusChanged: (status) {
              setState(() => _selectedStatus = status);
              _load(forceRefresh: true);
            },
          ),
          Expanded(
            child: _buildBody(
              state,
              canDelete,
              canChangeStatus,
              canRecordSupplies,
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate ? _buildFAB() : null,
    );
  }

  Map<String?, int> _buildCounts(TreatmentPlanState state) {
    final counts = <String?, int>{null: state.plans.length};
    for (final plan in state.plans) {
      counts[plan.status] = (counts[plan.status] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final created = await context.pushNamed<bool>(
          RouteNames.treatmentPlanCreate,
          extra: {
            if (widget.patientId != null) 'patient_id': widget.patientId,
            if (widget.doctorId != null) 'doctor_id': widget.doctorId,
          },
        );
        if (created == true && mounted) _load(forceRefresh: true);
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'New Plan',
        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildBody(
    TreatmentPlanState state,
    bool canDelete,
    bool canChangeStatus,
    bool canRecordSupplies,
  ) {
    if (state.isListLoading) return const _LoadingView();

    if (state.hasListError) {
      return _ErrorView(
        message: state.listError ?? 'Failed to load treatment plans',
        onRetry: () => _load(forceRefresh: true),
      );
    }

    if (state.isEmpty) {
      return TreatmentPlanEmptyState(onRefresh: () => _load(forceRefresh: true));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.background,
      onRefresh: () => ref.read(treatmentPlanProvider.notifier).refresh(),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            itemCount: state.plans.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.plans.length) {
                return const _LoadMoreIndicator();
              }
              final plan = state.plans[index];
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
                child: TreatmentPlanCard(
                  plan: plan,
                  canDelete: canDelete,
                  canChangeStatus: canChangeStatus,
                  canRecordSupplies: canRecordSupplies,
                  onDelete: () => _delete(plan.id, plan.name),
                  onChangeStatus: () => _changeStatus(plan),
                  onRecordSupplies: () => _recordSupplies(plan),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingMedium,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.iconBadgeSize,
            height: AppDimensions.iconBadgeSize,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: AppColors.primary,
              size: AppDimensions.iconSize,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treatment Plans', style: AppTextStyles.titleLarge),
                Text(
                  'Manage patient treatment plans and their statuses',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _PlanFilterBar extends StatelessWidget {
  const _PlanFilterBar({
    required this.selectedStatus,
    required this.counts,
    required this.onStatusChanged,
  });

  final String? selectedStatus;
  final Map<String?, int> counts;
  final ValueChanged<String?> onStatusChanged;

  static const _filters = <({
    String label,
    String? value,
    IconData? icon,
    Color? color,
  })>[
    (label: 'All', value: null, icon: null, color: null),
    (
      label: 'Draft',
      value: 'draft',
      icon: Icons.edit_note_rounded,
      color: AppColors.textSecondary,
    ),
    (
      label: 'Proposed',
      value: 'proposed',
      icon: Icons.mark_email_read_rounded,
      color: AppColors.info,
    ),
    (
      label: 'Accepted',
      value: 'accepted',
      icon: Icons.thumb_up_rounded,
      color: AppColors.warning,
    ),
    (
      label: 'Completed',
      value: 'completed',
      icon: Icons.done_all_rounded,
      color: AppColors.success,
    ),
    (
      label: 'Rejected',
      value: 'rejected',
      icon: Icons.cancel_rounded,
      color: AppColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimensions.paddingXS),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final item = _filters[index];
            final isSelected = selectedStatus == item.value;
            final count = counts[item.value] ?? 0;
            return _FilterChip(
              label: item.label,
              icon: item.icon,
              accentColor: item.color,
              count: count,
              isSelected: isSelected,
              onTap: () => onStatusChanged(item.value),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? accentColor;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: 14,
                color: activeColor,
              ),
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: activeColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : AppColors.border.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? activeColor : AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── State Views ──────────────────────────────────────────────────────────────

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
            'Loading treatment plans...',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
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
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
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
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Something went wrong', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              message,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
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
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}