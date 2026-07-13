// lib/presentation/pages/treatments/widgets/treatment_card.dart

import 'package:flutter/material.dart';
import '../../../../data/models/treatment/treatment_model.dart';
import 'treatment_info_chip.dart';

class TreatmentCard extends StatelessWidget {
  final TreatmentModel treatment;
  final bool canDelete;
  final VoidCallback onDelete;

  const TreatmentCard({
    super.key,
    required this.treatment,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Card(
      elevation: 0,
      color:     cs.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  cs.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.medical_services_rounded,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    treatment.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (treatment.description != null &&
                      treatment.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      treatment.description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing:    6,
                    runSpacing: 4,
                    children: [
                      TreatmentInfoChip(
                        label: treatment.formattedPrice,
                        icon:  Icons.monetization_on_outlined,
                        color: Colors.green,
                      ),
                      TreatmentInfoChip(
                        label: treatment.durationLabel,
                        icon:  Icons.timer_outlined,
                        color: Colors.blue,
                      ),
                      TreatmentInfoChip(
                        label: treatment.isActive
                            ? 'Active'
                            : 'Inactive',
                        icon: treatment.isActive
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: treatment.isActive
                            ? Colors.teal
                            : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ Delete: only if permitted
            if (canDelete)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }
}