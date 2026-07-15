// lib/presentation/pages/treatment_plans/widgets/plan_review_summary.dart

import 'package:flutter/material.dart';

import '../../../../data/models/patient/patient_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';

class PlanReviewSummary extends StatelessWidget {
  final String name;
  final String notes;
  final PatientModel? patient;
  final String? doctorLabel;
  final List<TreatmentPlanItemForm> items;
  final double grandTotal;

  const PlanReviewSummary({
    super.key,
    required this.name,
    required this.notes,
    required this.patient,
    required this.doctorLabel,
    required this.items,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan name
        _sectionTitle(context, Icons.assignment_outlined, 'Plan Details'),
        const SizedBox(height: 10),
        _infoRow(context, 'Name', name.isEmpty ? '—' : name),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoRow(context, 'Notes', notes),
        ],
        const SizedBox(height: 20),

        // Participants
        _sectionTitle(context, Icons.groups_outlined, 'Participants'),
        const SizedBox(height: 10),
        _infoRow(context, 'Patient', patient?.name ?? '—',
            subtitle: patient?.phone),
        const SizedBox(height: 8),
        _infoRow(context, 'Doctor', doctorLabel ?? '—'),
        const SizedBox(height: 20),

        // Steps
        _sectionTitle(context, Icons.medical_information_outlined,
            'Treatment Steps · ${items.length}'),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final t = item.selectedTreatment;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t?.name ?? 'Untitled',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '₱${item.price.toStringAsFixed(2)} × ${item.quantity}',
                        style: TextStyle(
                            fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₱${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(
                '₱${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {String? subtitle}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  TextStyle(fontSize: 13, color: theme.hintColor)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: theme.hintColor)),
            ],
          ),
        ),
      ],
    );
  }
}