// lib/presentation/pages/treatment_plans/treatment_plans_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/presentation/constant/permission_constants.dart';
import '../../providers/auth/auth_provider.dart';
import '/presentation/providers/treatment/treatment_plan_provider.dart';
import '../../route/route_names.dart';
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
  ConsumerState<TreatmentPlansPage> createState() =>
      _TreatmentPlansPageState();
}

class _TreatmentPlansPageState
    extends ConsumerState<TreatmentPlansPage> {
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
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
      _showSnack('No permission to delete treatment plans', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Treatment Plan?'),
          ],
        ),
        content: Text(
          'Delete "$name"?\n\n'
          'This will remove all plan items. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );

    final success = await ref
        .read(treatmentPlanProvider.notifier)
        .deletePlan(id);

    if (!mounted) return;
    Navigator.pop(context);

    _showSnack(
      success
          ? 'Treatment plan deleted'
          : ref.read(treatmentPlanProvider).listError ??
              'Failed to delete',
      success ? Colors.green : Colors.red,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentPlanProvider);
    final auth = ref.watch(authStateProvider);
    final canCreate = auth.hasPermission(Perm.treatmentPlanCreate);
    final canDelete = auth.hasPermission(Perm.treatmentPlanDelete);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Plans'),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          TreatmentPlanStatusFilter(
            selected: _selectedStatus ?? 'all',
            options: _statusOptions,
            onChanged: (status) {
              setState(() => _selectedStatus = status);
              _load(forceRefresh: true);
            },
          ),
          Expanded(child: _buildBody(state, canDelete)),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(
                RouteNames.treatmentPlanCreate,
                extra: {
                  if (widget.patientId != null)
                    'patient_id': widget.patientId,
                  if (widget.doctorId != null)
                    'doctor_id': widget.doctorId,
                },
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Plan'),
            )
          : null,
    );
  }

  Widget _buildBody(TreatmentPlanState state, bool canDelete) {
    if (state.isListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasListError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.listError ?? 'Failed to load',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _load(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return TreatmentPlanEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(treatmentPlanProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
            state.plans.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.plans.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final plan = state.plans[index];
          return TreatmentPlanCard(
            plan: plan,
            canDelete: canDelete,
            onDelete: () => _delete(plan.id, plan.name),
          );
        },
      ),
    );
  }
}