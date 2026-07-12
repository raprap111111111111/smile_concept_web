// lib/presentation/pages/prescriptions/prescriptions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/prescription/prescription_provider.dart';
import '../../route/route_names.dart';
import 'widgets/prescription_card.dart';
import 'widgets/prescription_empty_state.dart';

class PrescriptionsPage extends ConsumerStatefulWidget {
  final int? patientId;

  const PrescriptionsPage({super.key, this.patientId});

  @override
  ConsumerState<PrescriptionsPage> createState() =>
      _PrescriptionsPageState();
}

class _PrescriptionsPageState
    extends ConsumerState<PrescriptionsPage> {
  final ScrollController _scrollController = ScrollController();

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

  // ── Helpers ────────────────────────────────────────────────
  AuthState get _auth => ref.read(authStateProvider);

  void _load({bool forceRefresh = false}) {
    ref.read(prescriptionProvider.notifier).loadPrescriptions(
          patientId: widget.patientId,
          forceRefresh: forceRefresh,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(prescriptionProvider.notifier).loadMore();
    }
  }

  void _openDetail(int prescriptionId) {
    context.pushNamed(
      RouteNames.prescriptionDetail,
      pathParameters: {'id': prescriptionId.toString()},
    );
  }

  // ── Permission-Guarded Delete ──────────────────────────────
  Future<void> _deletePrescription(int id) async {
    // ✅ RBAC check BEFORE any action
    if (!_auth.canDeletePrescription) {
      _showPermissionDenied('delete prescriptions');
      return;
    }

    final success = await ref
        .read(prescriptionProvider.notifier)
        .deletePrescription(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      success
          ? const SnackBar(
              content: Text('✅ Prescription deleted'),
              backgroundColor: Colors.green,
            )
          : SnackBar(
              content: Text(
                ref.read(prescriptionProvider).listError ??
                    'Failed to delete',
              ),
              backgroundColor: Colors.red,
            ),
    );
  }

  void _showPermissionDenied(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ You do not have permission to $action'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(prescriptionProvider);
    final authState = ref.watch(authStateProvider);

    // ── Derived permission flags ───────────────────────────
    final canCreate = authState.canCreatePrescription;
    final canDelete = authState.canDeletePrescription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(state, canDelete),

      // ✅ FAB only shown if user CAN create
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.pushNamed(RouteNames.prescriptionCreate),
              icon: const Icon(Icons.add),
              label: const Text('New Prescription'),
            )
          : null,
    );
  }

  Widget _buildBody(PrescriptionState state, bool canDelete) {
    // ── Loading ────────────────────────────────────────────
    if (state.isListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Error ──────────────────────────────────────────────
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
                state.listError ?? 'Failed to load prescriptions',
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

    // ── Empty ──────────────────────────────────────────────
    if (state.isEmpty) {
      return PrescriptionEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    // ── List ───────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(prescriptionProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: state.prescriptions.length +
            (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // ── Load more indicator ──────────────────────
          if (index == state.prescriptions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final prescription = state.prescriptions[index];

          // ✅ Swipe-to-delete ONLY if user has permission
          if (canDelete) {
            return _DismissiblePrescriptionCard(
              prescription: prescription,
              onTap: () => _openDetail(prescription.id),
              onDelete: () => _deletePrescription(prescription.id),
            );
          }

          // ── Read-only card (no swipe) ─────────────────
          return PrescriptionCard(
            prescription: prescription,
            onTap: () => _openDetail(prescription.id),
          );
        },
      ),
    );
  }
}

// ─── Dismissible Card (extracted for clarity) ─────────────────
class _DismissiblePrescriptionCard extends StatelessWidget {
  final dynamic prescription;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DismissiblePrescriptionCard({
    required this.prescription,
    required this.onTap,
    required this.onDelete,
  });

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prescription?'),
        content: Text(
          'Are you sure you want to delete '
          'Prescription #${prescription.id}?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(prescription.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: PrescriptionCard(
        prescription: prescription,
        onTap: onTap,
      ),
    );
  }
}