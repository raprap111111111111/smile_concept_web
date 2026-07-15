// lib/presentation/pages/treatment_plans/widgets/treatment_plan_card.dart

import 'package:flutter/material.dart';

import '../../../../data/models/treatment/treatment_plan_model.dart';

class TreatmentPlanCard extends StatelessWidget {
  final TreatmentPlanModel plan;
  final bool canDelete;
  final bool canChangeStatus;
  final VoidCallback onDelete;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onTap;

  const TreatmentPlanCard({
    super.key,
    required this.plan,
    required this.canDelete,
    required this.onDelete,
    this.canChangeStatus = false,
    this.onChangeStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(plan.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header strip ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                      color: statusColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_outlined,
                      color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plan.name.isEmpty ? 'Untitled Plan' : plan.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(context, statusColor),
                  if (canDelete)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      tooltip: 'Delete plan',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient row
                  if (plan.hasPatient)
                    _infoRow(
                      context,
                      icon: Icons.person_outline,
                      label: 'Patient',
                      value: plan.patient!.name,
                    ),

                  // Doctor row
                  if (plan.hasDoctor) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      context,
                      icon: Icons.medical_services_outlined,
                      label: 'Doctor',
                      value: plan.doctor!.name,
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(
                      height: 1,
                      color: theme.colorScheme.outline
                          .withValues(alpha: 0.15)),
                  const SizedBox(height: 12),

                  // Bottom: items count + total
                  Row(
                    children: [
                      Icon(Icons.medical_information_outlined,
                          size: 16, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Text(
                        '${plan.items.length} step${plan.items.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 12, color: theme.hintColor),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ',
                        style: TextStyle(
                            fontSize: 12, color: theme.hintColor),
                      ),
                      Text(
                        plan.formattedTotal,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status chip (tappable if allowed) ─────────────────────
  Widget _buildStatusChip(BuildContext context, Color color) {
    final tappable = canChangeStatus && onChangeStatus != null;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            plan.statusLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ],
      ),
    );

    if (!tappable) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onChangeStatus,
        child: chip,
      ),
    );
  }

  // ─── Reusable info row ─────────────────────────────────────
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Status → color map ────────────────────────────────────
  Color _statusColor(String status) {
    return switch (status) {
      'draft' => Colors.grey,
      'proposed' => Colors.blue,
      'accepted' => Colors.green,
      'completed' => Colors.teal,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
  }
}