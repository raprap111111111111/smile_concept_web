// lib/presentation/pages/prescriptions/prescriptions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/prescription/prescription_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
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

  void _openDetail(int id) {
    context.pushNamed(
      RouteNames.prescriptionDetail,
      pathParameters: {'id': id.toString()},
    );
  }

  Future<void> _deletePrescription(int id) async {
    if (!_auth.canDeletePrescription) {
      _showSnack('You do not have permission to delete prescriptions',
          isError: true);
      return;
    }

    final success = await ref
        .read(prescriptionProvider.notifier)
        .deletePrescription(id);

    if (!mounted) return;

    if (success) {
      _showSnack('Prescription deleted successfully');
    } else {
      _showSnack(
        ref.read(prescriptionProvider).listError ?? 'Failed to delete',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionProvider);
    final authState = ref.watch(authStateProvider);
    final canCreate = authState.canCreatePrescription;
    final canDelete = authState.canDeletePrescription;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppDimensions.paddingLarge,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accentWithOpacity(0.15),
                borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadius),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Prescriptions',
                    style: AppTextStyles.titleLarge),
                if (!state.isListLoading &&
                    state.prescriptions.isNotEmpty)
                  Text(
                    '${state.prescriptions.length} total',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_outlined,
                color: AppColors.textSecondary),
            tooltip: 'Refresh',
          ),
          if (canCreate) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(
                  right: AppDimensions.paddingLarge),
              child: FilledButton.icon(
                onPressed: () =>
                    context.pushNamed(RouteNames.prescriptionCreate),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Prescription',
                    style: AppTextStyles.labelLarge),
              ),
            ),
          ],
        ],
      ),
      body: _buildBody(state, canDelete),
    );
  }

  Widget _buildBody(PrescriptionState state, bool canDelete) {
    if (state.isListLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasListError) {
      return _ErrorView(
        message: state.listError ?? 'Failed to load prescriptions',
        onRetry: () => _load(forceRefresh: true),
      );
    }

    if (state.isEmpty) {
      return PrescriptionEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(prescriptionProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        itemCount: state.prescriptions.length +
            (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          if (index == state.prescriptions.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
            );
          }

          final prescription = state.prescriptions[index];

          if (canDelete) {
            return _DismissiblePrescriptionCard(
              prescription: prescription,
              onTap: () => _openDetail(prescription.id),
              onDelete: () => _deletePrescription(prescription.id),
            );
          }

          return PrescriptionCard(
            prescription: prescription,
            onTap: () => _openDetail(prescription.id),
          );
        },
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text('Something went wrong',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(message,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.paddingLarge),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dismissible Card ──────────────────────────────────────────
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
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          side: const BorderSide(color: AppColors.line),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Prescription',
                style: AppTextStyles.titleMedium),
          ],
        ),
        content: Text(
          'Are you sure you want to delete '
          'Prescription #${prescription.id}? '
          'This action cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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