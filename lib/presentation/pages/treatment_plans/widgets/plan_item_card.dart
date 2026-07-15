// lib/presentation/pages/treatment_plans/widgets/plan_item_card.dart

import 'package:flutter/material.dart';

import '../../../../data/models/treatment/treatment_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';
import 'treatment_picker_field.dart';

class PlanItemCard extends StatelessWidget {
  final int index;
  final TreatmentPlanItemForm item;
  final List<TreatmentModel> availableTreatments;
  final bool isLoading;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const PlanItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.availableTreatments,
    required this.isLoading,
    required this.onChanged,
    this.onMoveUp,
    this.onMoveDown,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = item.selectedTreatment;
    final hasSelection = selected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.treatmentError
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: item.treatmentError ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Header bar ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                        hasSelection
                            ? selected.name
                            : 'Untitled Step',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: hasSelection ? null : theme.hintColor,
                          fontStyle: hasSelection
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasSelection)
                        Text(
                          '₱${item.subtotal.toStringAsFixed(2)}  '
                          '· Qty ${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                _iconBtn(Icons.arrow_upward, onMoveUp, 'Move up'),
                _iconBtn(Icons.arrow_downward, onMoveDown, 'Move down'),
                _iconBtn(Icons.delete_outline, onRemove, 'Remove',
                    color: Colors.red.shade400),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TreatmentPickerField(
                  item: item,
                  treatments: availableTreatments,
                  isLoading: isLoading,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 14),

                // Price + Qty
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _labeled(
                        context,
                        'Unit Price',
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₱ ${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _labeled(
                          context, 'Quantity', _qtyStepper(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: item.notesController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add notes for this step (optional)',
                    hintStyle: TextStyle(
                        color: theme.hintColor, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.edit_note, size: 18),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap, String tip,
      {Color? color}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _labeled(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _qtyStepper(BuildContext context) {
    final theme = Theme.of(context);
    final canDec = item.quantity > 1;
    final canInc = item.quantity < 99;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: canDec
                ? () {
                    item.quantity--;
                    onChanged();
                  }
                : null,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 13),
              child: Icon(Icons.remove,
                  size: 18,
                  color: canDec
                      ? theme.colorScheme.primary
                      : theme.disabledColor),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          InkWell(
            onTap: canInc
                ? () {
                    item.quantity++;
                    onChanged();
                  }
                : null,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 13),
              child: Icon(Icons.add,
                  size: 18,
                  color: canInc
                      ? theme.colorScheme.primary
                      : theme.disabledColor),
            ),
          ),
        ],
      ),
    );
  }
}