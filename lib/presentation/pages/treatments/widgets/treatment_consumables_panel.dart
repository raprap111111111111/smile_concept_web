// lib/presentation/pages/treatments/widgets/treatment_consumables_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_message.dart';
import '../../../../data/models/inventory/inventory_item_model.dart';
import '../../../../data/models/inventory/treatment_consumable_model.dart';
import '../../../providers/inventory/inventory_form_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/shared/item_picker_dialog.dart';

/// Edits which supplies a treatment consumes.
///
/// Lives on the treatment form because a recipe has no meaning apart from the
/// treatment it describes — an extraction always uses roughly the same
/// supplies, and the clinic states that once here rather than re-entering it
/// for every patient.
///
/// Holds its lines in the parent's state rather than saving on each keystroke:
/// the recipe is saved with the rest of the form, so an abandoned edit changes
/// nothing.
class TreatmentConsumablesPanel extends ConsumerWidget {
  final List<TreatmentConsumableModel> consumables;
  final ValueChanged<List<TreatmentConsumableModel>> onChanged;

  const TreatmentConsumablesPanel({
    super.key,
    required this.consumables,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsSimpleListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock is drawn down automatically when an appointment using this '
          'treatment is completed.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        if (consumables.isEmpty)
          _EmptyLine()
        else
          ...consumables.map(
            (line) => _ConsumableRow(
              key: ValueKey(line.itemId),
              line: line,
              onQuantityChanged: (value) => _replace(
                line.copyWith(quantityPerUse: value),
              ),
              onOptionalChanged: (value) => _replace(
                line.copyWith(isOptional: value),
              ),
              onRemove: () => onChanged(
                consumables.where((c) => c.itemId != line.itemId).toList(),
              ),
            ),
          ),

        const SizedBox(height: AppDimensions.paddingSmall),
        _AddButton(
          itemsAsync: itemsAsync,
          alreadyAdded: consumables.map((c) => c.itemId).toSet(),
          onRetry: () => ref.invalidate(itemsSimpleListProvider),
          onPicked: (item) => onChanged([
            ...consumables,
            TreatmentConsumableModel(
              itemId: item.id,
              quantityPerUse: 1,
              item: item,
            ),
          ]),
        ),
      ],
    );
  }

  void _replace(TreatmentConsumableModel updated) {
    onChanged([
      for (final line in consumables)
        line.itemId == updated.itemId ? updated : line,
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// ROW
// ─────────────────────────────────────────────────────────
class _ConsumableRow extends StatefulWidget {
  final TreatmentConsumableModel line;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<bool> onOptionalChanged;
  final VoidCallback onRemove;

  const _ConsumableRow({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onOptionalChanged,
    required this.onRemove,
  });

  @override
  State<_ConsumableRow> createState() => _ConsumableRowState();
}

class _ConsumableRowState extends State<_ConsumableRow> {
  late final TextEditingController _quantity =
      TextEditingController(text: widget.line.quantityPerUse.toString());

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.line.item?.unitOfMeasure ?? 'unit';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.line.displayName,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.line.item?.sku != null)
                  Text(
                    widget.line.item!.sku!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),

          // Per single performance of the treatment. Three fillings multiply
          // this by three at deduction time.
          SizedBox(
            width: 74,
            child: TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Qty',
                helperText: unit,
                helperMaxLines: 1,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  widget.onQuantityChanged(parsed);
                }
              },
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),

          Tooltip(
            message: widget.line.isOptional
                ? 'Optional — listed but not deducted'
                : 'Deducted automatically',
            child: IconButton(
              onPressed: () => widget.onOptionalChanged(!widget.line.isOptional),
              icon: Icon(
                widget.line.isOptional
                    ? Icons.check_box_outline_blank
                    : Icons.check_box,
                color: widget.line.isOptional
                    ? AppColors.textMuted
                    : AppColors.primary,
                size: AppDimensions.iconSizeMedium,
              ),
            ),
          ),

          IconButton(
            onPressed: widget.onRemove,
            tooltip: 'Remove',
            icon: const Icon(
              Icons.close,
              color: AppColors.error,
              size: AppDimensions.iconSizeMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// EMPTY
// ─────────────────────────────────────────────────────────
class _EmptyLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              'No consumables yet. Without them, completing an appointment '
              'will not draw anything from stock.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ADD
// ─────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final AsyncValue<List<InventoryItemModel>> itemsAsync;
  final Set<int> alreadyAdded;
  final ValueChanged<InventoryItemModel> onPicked;
  final VoidCallback onRetry;

  const _AddButton({
    required this.itemsAsync,
    required this.alreadyAdded,
    required this.onPicked,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Loading items...'),
      ),
      error: (e, _) => Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              describeError(e),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.error),
            ),
          ),
          // A 403 is settled server-side; retrying only repeats it.
          if (!isPermissionError(e))
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
      data: (items) {
        final available =
            items.where((i) => !alreadyAdded.contains(i.id)).toList();

        return OutlinedButton.icon(
          onPressed: available.isEmpty
              ? null
              : () => _pick(context, available),
          icon: const Icon(Icons.add, size: AppDimensions.iconSizeSmall),
          label: Text(
            available.isEmpty ? 'All items added' : 'Add consumable',
          ),
        );
      },
    );
  }

  Future<void> _pick(
    BuildContext context,
    List<InventoryItemModel> available,
  ) async {
    final picked = await showDialog<InventoryItemModel>(
      context: context,
      builder: (context) => ItemPickerDialog(items: available),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }
}

