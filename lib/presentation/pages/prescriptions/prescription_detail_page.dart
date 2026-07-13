// lib/presentation/pages/prescriptions/prescription_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/prescription/prescription_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/prescription/prescription_provider.dart';
import 'widgets/prescription_item_tile.dart';

class PrescriptionDetailPage extends ConsumerStatefulWidget {
  final int prescriptionId;

  const PrescriptionDetailPage({
    super.key,
    required this.prescriptionId,
  });

  @override
  ConsumerState<PrescriptionDetailPage> createState() =>
      _PrescriptionDetailPageState();
}

class _PrescriptionDetailPageState
    extends ConsumerState<PrescriptionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(prescriptionProvider.notifier)
          .loadById(widget.prescriptionId);
    });
  }

  // ── Auth helper ────────────────────────────────────────────
  AuthState get _auth => ref.read(authStateProvider);

  // ── Permission-Guarded Delete ──────────────────────────────
  Future<void> _confirmAndDelete() async {
    // ✅ Step 1: Check permission FIRST — before showing any UI
    if (!_auth.canDeletePrescription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ You do not have permission to delete prescriptions',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // ← hard stop
    }

    // ✅ Step 2: Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Prescription'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete '
          'Prescription #${widget.prescriptionId}?\n\n'
          'This will also delete all medicines inside it. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // ✅ Step 3: Loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );

    // ✅ Step 4: Execute delete
    final success = await ref
        .read(prescriptionProvider.notifier)
        .deletePrescription(widget.prescriptionId);

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Prescription deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(prescriptionProvider).listError ??
                'Failed to delete prescription',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(prescriptionProvider);
    final authState = ref.watch(authStateProvider);

    // ✅ Inline permission checks — no widget needed
    final canDelete = authState.canDeletePrescription;
    final canPrint  = authState.canPrintPrescription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
        actions: [
          // ── Refresh: always visible ────────────────────
          IconButton(
            onPressed: () => ref
                .read(prescriptionProvider.notifier)
                .loadById(widget.prescriptionId,
                    forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),

          // ✅ Print: only for dentist/admin
          if (canPrint)
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('🖨️ Print coming soon')),
                );
              },
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print Prescription',
            ),

          // ✅ Delete: only if user has permission
          if (canDelete)
            IconButton(
              onPressed: _confirmAndDelete,
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red),
              tooltip: 'Delete Prescription',
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, PrescriptionState state) {
    // ── Loading ────────────────────────────────────────────
    if (state.isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Error ──────────────────────────────────────────────
    if (state.hasDetailError) {
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
                state.detailError ??
                    'Failed to load prescription',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(prescriptionProvider.notifier)
                    .loadById(widget.prescriptionId,
                        forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ──────────────────────────────────────────────
    final prescription = state.selected;
    if (prescription == null) return const SizedBox.shrink();

    // ── Content ────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(prescription: prescription),
          const SizedBox(height: 20),

          Text(
            'Medicines',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
          ),
          const SizedBox(height: 12),

          if (prescription.hasItems)
            ...prescription.items.asMap().entries.map(
                  (entry) => PrescriptionItemTile(
                    item: entry.value,
                    index: entry.key + 1,
                  ),
                )
          else
            const Text('No medicines listed'),

          if (prescription.hasNotes) ...[
            const SizedBox(height: 20),
            Text(
              "Doctor's Notes",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
              ),
              child: Text(
                prescription.notes!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Header Card & Info Row remain the same as before ──────────
class _HeaderCard extends StatelessWidget {
  final PrescriptionModel prescription;
  const _HeaderCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.medication_rounded,
                      color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescription #${prescription.id}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prescription.formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            if (prescription.doctor != null)
              _InfoRow(
                label: 'Doctor',
                value: 'Dr. ${prescription.doctor!.displayName}',
                subValue: prescription.doctor!.specialty,
              ),
            if (prescription.patient != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Patient',
                value: prescription.patient!.name,
                subValue: prescription.patient!.email,
              ),
            ],
            if (prescription.appointmentId != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Appointment',
                value: '#${prescription.appointmentId}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;

  const _InfoRow({
    required this.label,
    required this.value,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subValue != null && subValue!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subValue!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}