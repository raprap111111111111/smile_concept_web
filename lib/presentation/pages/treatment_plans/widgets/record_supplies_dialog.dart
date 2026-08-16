// lib/presentation/pages/treatment_plans/widgets/record_supplies_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_message.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/inventory/inventory_item_model.dart';
import '../../../../data/models/inventory/stock_movement_model.dart';
import '../../../../data/models/treatment/plan_consumables_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';
import '../../../../data/repositories/treatment_plan_repository.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/inventory/inventory_form_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/item_picker_dialog.dart';
import '../../../widgets/shared/picker_dialog_chrome.dart';
import '../../inventory/widgets/branch_dropdown.dart';

/// Records the supplies a completed treatment plan actually used.
///
/// Opens prefilled from the treatment recipes — quantity_per_use times how
/// often each procedure was planned — because the recipe is right most of the
/// time and staff only need to correct the exceptions.
///
/// Recording happens once per plan. Corrections go through the inventory
/// adjustment flow, which keeps the ledger append-only.
///
/// Pops `true` when something was recorded, so the caller can refresh.
class RecordSuppliesDialog extends ConsumerStatefulWidget {
  final TreatmentPlanModel plan;

  const RecordSuppliesDialog({super.key, required this.plan});

  static Future<bool?> show(BuildContext context, TreatmentPlanModel plan) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RecordSuppliesDialog(plan: plan),
    );
  }

  @override
  ConsumerState<RecordSuppliesDialog> createState() =>
      _RecordSuppliesDialogState();
}

class _SupplyLine {
  final int itemId;
  final String name;
  final String? unit;
  final bool isOptional;
  int quantity;

  _SupplyLine({
    required this.itemId,
    required this.name,
    this.unit,
    this.isOptional = false,
    required this.quantity,
  });
}

class _RecordSuppliesDialogState extends ConsumerState<RecordSuppliesDialog> {
  final _notesController = TextEditingController();

  PlanConsumablesStatusModel? _status;
  Object? _loadError;
  bool _isLoading = true;
  bool _isSubmitting = false;

  int? _branchId;
  bool _branchDefaulted = false;

  List<_SupplyLine> _lines = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await ref
          .read(treatmentPlanRepositoryProvider)
          .fetchConsumables(widget.plan.id);

      if (!mounted) return;

      setState(() {
        _status = status;
        _lines = status.suggestedLines
            .map((line) => _SupplyLine(
                  itemId: line.itemId,
                  name: line.name,
                  unit: line.unitOfMeasure,
                  isOptional: line.isOptional,
                  quantity: line.suggestedQuantity,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _isLoading = false;
      });
    }
  }

  /// The user's own branch is only a sensible default once it is known to be
  /// one of the branches they may write to — a DropdownButtonFormField throws
  /// when handed a value its items do not contain.
  void _defaultBranch(List<dynamic> branches) {
    if (_branchDefaulted) return;

    final mine = ref.read(authStateProvider).user?.branchId;
    _branchDefaulted = true;

    if (mine == null) return;
    if (!branches.any((b) => b.id == mine)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _branchId == null) setState(() => _branchId = mine);
    });
  }

  Future<void> _submit() async {
    if (_branchId == null) {
      ToastHelper.warning(context, 'Choose the branch these supplies came from.');
      return;
    }

    final lines = _lines.where((line) => line.quantity > 0).toList();

    if (lines.isEmpty) {
      ToastHelper.warning(context, 'Add at least one supply with a quantity.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result =
          await ref.read(treatmentPlanRepositoryProvider).recordConsumables(
                planId: widget.plan.id,
                branchId: _branchId!,
                lines: lines
                    .map((line) => <String, dynamic>{
                          'item_id': line.itemId,
                          'quantity': line.quantity,
                        })
                    .toList(),
                notes: _notesController.text,
              );

      if (!mounted) return;

      if (result.hasShortfall) {
        ToastHelper.warning(
          context,
          'Recorded, but ${result.shortfalls.length} item(s) ran short — '
          'their balances are now negative.',
        );
      } else {
        ToastHelper.success(context, 'Supplies recorded and stock deducted.');
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastHelper.fromError(context, e,
          fallback: 'Could not record these supplies.');
    }
  }

  Future<void> _addLine(List<InventoryItemModel> catalog) async {
    final taken = _lines.map((line) => line.itemId).toSet();
    final available =
        catalog.where((item) => !taken.contains(item.id)).toList();

    if (available.isEmpty) {
      ToastHelper.info(context, 'Every item is already on the list.');
      return;
    }

    final picked = await showDialog<InventoryItemModel>(
      context: context,
      builder: (_) => ItemPickerDialog(
        items: available,
        title: 'Add supply',
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _lines = [
        ..._lines,
        _SupplyLine(
          itemId: picked.id,
          name: picked.name,
          unit: picked.unitOfMeasure,
          quantity: 1,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // main.dart still runs ThemeData.dark(); this dialog is designed light, so
    // it pins the light theme the way the stock forms do — otherwise the text
    // fields and dropdowns render dark-on-dark.
    return Theme(
      data: AppTheme.lightTheme,
      child: Dialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          side: const BorderSide(color: AppColors.line),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PickerDialogHeader(
                icon: Icons.inventory_2_outlined,
                title: 'Record supplies used',
                subtitle: widget.plan.name,
              ),
              Flexible(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLarge * 2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              describeError(_loadError),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    if (_status?.recorded == true) {
      return _AlreadyRecorded(movements: _status!.movements);
    }

    return _buildForm();
  }

  Widget _buildForm() {
    final itemsAsync = ref.watch(itemsSimpleListProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            children: [
              const _DoubleDeductionWarning(),
              const SizedBox(height: AppDimensions.paddingMedium),

              Consumer(
                builder: (context, ref, _) {
                  final branches = ref.watch(branchesSimpleListProvider);
                  branches.whenData(_defaultBranch);

                  return BranchDropdown(
                    value: _branchId,
                    onChanged: (value) => setState(() => _branchId = value),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Text('Supplies', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppDimensions.paddingSmall),

              if (_lines.isEmpty)
                Text(
                  'No recipe covers this plan\'s procedures. Add what was used.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                )
              else
                ..._lines.map(
                  (line) => _SupplyRow(
                    key: ValueKey(line.itemId),
                    line: line,
                    onQuantityChanged: (value) =>
                        setState(() => line.quantity = value),
                    onRemove: () => setState(() {
                      _lines = _lines
                          .where((other) => other.itemId != line.itemId)
                          .toList();
                    }),
                  ),
                ),

              const SizedBox(height: AppDimensions.paddingSmall),
              itemsAsync.when(
                loading: () => const Text('Loading items...'),
                error: (e, _) => Text(
                  describeError(e),
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
                data: (catalog) => OutlinedButton.icon(
                  onPressed: () => _addLine(catalog),
                  icon: const Icon(Icons.add,
                      size: AppDimensions.iconSizeSmall),
                  label: const Text('Add supply'),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),
              TextField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 500,
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Anything worth remembering about this procedure',
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSubmitting ? 'Recording...' : 'Record supplies'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// WARNING
// ─────────────────────────────────────────────────────────

/// Plans and appointments are not linked, so nothing can tell whether an
/// appointment already deducted these supplies automatically. Staff can.
class _DoubleDeductionWarning extends StatelessWidget {
  const _DoubleDeductionWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // statusPendingInk rather than `warning`, which is a 1.6:1 glyph on
          // this tint.
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: AppColors.statusPendingInk),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              'Completed appointments already deduct their supplies '
              'automatically. Recording here deducts again — check the stock '
              'ledger first if this plan was carried out through appointments.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ROW
// ─────────────────────────────────────────────────────────

class _SupplyRow extends StatefulWidget {
  final _SupplyLine line;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _SupplyRow({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<_SupplyRow> createState() => _SupplyRowState();
}

class _SupplyRowState extends State<_SupplyRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.line.quantity.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.line.name, style: AppTextStyles.bodyMedium),
                if (widget.line.isOptional)
                  Text(
                    'Optional in the recipe',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          SizedBox(
            width: 74,
            child: TextFormField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Qty',
                helperText: widget.line.unit,
                isDense: true,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                // 0 and unparseable input are treated as "still typing";
                // submission filters empty lines out anyway.
                if (parsed != null && parsed > 0) {
                  widget.onQuantityChanged(parsed);
                }
              },
            ),
          ),
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, size: AppDimensions.iconSizeSmall),
            tooltip: 'Remove',
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ALREADY RECORDED
// ─────────────────────────────────────────────────────────

class _AlreadyRecorded extends StatelessWidget {
  final List<StockMovementModel> movements;

  const _AlreadyRecorded({required this.movements});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            shrinkWrap: true,
            children: [
              Text(
                'Supplies were already recorded for this plan. To correct them, '
                'use a stock adjustment — the ledger is never rewritten.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              ...movements.map(
                (movement) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          movement.displayName,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        movement.deltaLabel,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
