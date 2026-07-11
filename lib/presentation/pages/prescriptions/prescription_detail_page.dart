import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/prescription/prescription_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(prescriptionProvider.notifier)
                .loadById(widget.prescriptionId, forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, PrescriptionState state) {
    // ── Loading ──────────────────────────────────────────
    if (state.isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Error ────────────────────────────────────────────
    if (state.hasDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.detailError ?? 'Failed to load prescription',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(prescriptionProvider.notifier)
                    .loadById(widget.prescriptionId, forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ────────────────────────────────────────────
    final prescription = state.selected;
    if (prescription == null) {
      return const SizedBox.shrink();
    }

    // ── Content ──────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(prescription: prescription),
          const SizedBox(height: 20),

          Text(
            'Medicines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
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
                  child: Icon(
                    Icons.medication_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescription #${prescription.id}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prescription.formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
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
                subValue: prescription.doctor!.specialization,
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

// ─────────────────────────────────────────────────────────────
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subValue != null && subValue!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subValue!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}