// lib/presentation/pages/treatment_plans/treatment_plans_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/presentation/constant/permission_constants.dart';
import '/presentation/providers/treatment/treatment_plan_provider.dart';
import '../../../data/models/treatment/treatment_plan_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/status_change_dialog.dart';
import 'widgets/treatment_plan_card.dart';
import 'widgets/treatment_plan_empty_state.dart';
import 'widgets/treatment_plan_status_filter.dart';

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

  static const _statusOptions = [
    'all',
    'draft',
    'proposed',
    'accepted',
    'completed',
    'rejected',
  ];

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
          status: _selectedStatus == 'all' ? null : _selectedStatus,
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
      _showSnack('No permission to delete treatment plans', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildDeleteDialog(ctx, name),
    );

    if (confirmed != true || !mounted) return;

    _showLoadingDialog();

    final success =
        await ref.read(treatmentPlanProvider.notifier).deletePlan(id);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    _showSnack(
      success
          ? 'Treatment plan deleted'
          : ref.read(treatmentPlanProvider).listError ?? 'Failed to delete',
      isError: !success,
    );
  }

  Future<void> _changeStatus(TreatmentPlanModel plan) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.treatmentPlanUpdate)) {
      _showSnack('No permission to change status', isError: true);
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatusChangeDialog(currentStatus: plan.status),
    );

    if (result == null || !mounted) return;

    // Show loading dialog
    _showLoadingDialog();

    final error = await ref.read(treatmentPlanProvider.notifier).changeStatus(
          id: plan.id,
          status: result['status']!,
          reason: result['reason'],
        );

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    // Just refresh the list instead
    _load(forceRefresh: true);

    if (error == null) {
      _showSnack('Status changed to ${result['status']}', isError: false);
    } else {
      _showSnack(error, isError: true);
    }
  }
  // ─── Dialog helpers ──────────────────────────────────────

  Widget _buildDeleteDialog(BuildContext ctx, String name) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        side: const BorderSide(color: AppColors.line),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Delete Plan?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.ink),
          ),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            const TextSpan(text: 'Delete '),
            TextSpan(
              text: '"$name"',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const TextSpan(
              text:
                  '?\n\nThis will remove all plan items. This cannot be undone.',
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              side: const BorderSide(color: AppColors.line),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    final bgColor = isError ? AppColors.error : AppColors.success;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          TreatmentPlanStatusFilter(
            selected: _selectedStatus ?? 'all',
            options: _statusOptions,
            onChanged: (status) {
              setState(() => _selectedStatus = status);
              _load(forceRefresh: true);
            },
          ),
          Expanded(child: _buildBody(state, canDelete, canChangeStatus)),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.pushNamed<bool>(
                  RouteNames.treatmentPlanCreate,
                  extra: {
                    if (widget.patientId != null)
                      'patient_id': widget.patientId,
                    if (widget.doctorId != null) 'doctor_id': widget.doctorId,
                  },
                );
                if (created == true && mounted) {
                  _load(forceRefresh: true);
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add),
              label: const Text(
                'New Plan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
            )
          : null,
    );
  }

  // ─── Page Header ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingLarge,
        AppDimensions.paddingMedium,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.22),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Treatment Plans',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage patient treatment plans and their statuses',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Refresh',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _load(forceRefresh: true),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    TreatmentPlanState state,
    bool canDelete,
    bool canChangeStatus,
  ) {
    if (state.isListLoading) {
      return const Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    if (state.hasListError) {
      return _buildErrorState(state);
    }

    if (state.isEmpty) {
      return TreatmentPlanEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(treatmentPlanProvider.notifier).refresh(),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            itemCount: state.plans.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.plans.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                );
              }
              final plan = state.plans[index];
              return TreatmentPlanCard(
                plan: plan,
                canDelete: canDelete,
                canChangeStatus: canChangeStatus,
                onDelete: () => _delete(plan.id, plan.name),
                onChangeStatus: () => _changeStatus(plan),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(TreatmentPlanState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              state.listError ?? 'Failed to load treatment plans',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _load(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
