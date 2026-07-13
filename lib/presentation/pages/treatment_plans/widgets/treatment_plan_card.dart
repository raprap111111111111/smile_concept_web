// lib/presentation/pages/treatment_plans/widgets/treatment_plan_card.dart

import 'package:flutter/material.dart';
import '/data/models/treatment/treatment_plan_model.dart';
import 'treatment_plan_info_row.dart';

class TreatmentPlanCard extends StatelessWidget {
  final TreatmentPlanModel plan;
  final bool canDelete;
  final VoidCallback onDelete;

  const TreatmentPlanCard({
    super.key,
    required this.plan,
    required this.canDelete,
    required this.onDelete,
  });

  Color get _statusColor => switch (plan.status) {
        'accepted'  => Colors.green,
        'completed' => Colors.teal,
        'rejected'  => Colors.red,
        'proposed'  => Colors.orange,
        'draft'     => Colors.grey,
        _           => Colors.blue,
      };

  IconData get _statusIcon => switch (plan.status) {
        'accepted'  => Icons.check_circle_outline,
        'completed' => Icons.task_alt_rounded,
        'rejected'  => Icons.cancel_outlined,
        'proposed'  => Icons.pending_outlined,
        'draft'     => Icons.edit_outlined,
        _           => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Card(
      elevation: 0,
      color:     cs.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      cs.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: cs.primary,
                    size:  20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Est. Total: ${plan.formattedTotal}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),

                // ── Status badge ──────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon,
                          size:  12,
                          color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        plan.statusLabel,
                        style: TextStyle(
                          fontSize:   11,
                          color:      _statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Delete button
                if (canDelete) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size:  20,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),

            // ── Doctor & Patient ───────────────────────────
            if (plan.doctor != null ||
                plan.patient != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (plan.doctor != null)
                    Expanded(
                      child: TreatmentPlanInfoRow(
                        icon:  Icons.person_outlined,
                        label: 'Dr. ${plan.doctor!.name}',
                        sub:   plan.doctor!.specialization,
                      ),
                    ),
                  if (plan.patient != null)
                    Expanded(
                      child: TreatmentPlanInfoRow(
                        icon:  Icons.face_outlined,
                        label: plan.patient!.name,
                        sub:   plan.patient!.email,
                      ),
                    ),
                ],
              ),
            ],

            // ── Steps ─────────────────────────────────────
            if (plan.hasItems) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Treatment Steps (${plan.items.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:         Colors.grey.shade600,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              ...plan.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width:  22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.primary
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.sequenceOrder}',
                          style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w700,
                            color:      cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.treatment?.name ??
                              'Treatment #${item.treatmentId}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.formattedCost,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Notes ─────────────────────────────────────
            if (plan.hasNotes) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_outlined,
                        size:  14,
                        color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plan.notes!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}