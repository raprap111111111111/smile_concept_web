// lib/presentation/pages/inventory/stock_action_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/toast_helper.dart';
import '../../providers/inventory/inventory_provider.dart';
import '../../providers/inventory/stock_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'widgets/branch_dropdown.dart';
import 'widgets/item_dropdown.dart';

/// Which of the three single-branch stock verbs this form is performing.
///
/// They share a shape — pick a branch, pick an item, give a number — so they
/// share a page. Transfer is separate: it names two branches and is the one
/// outflow the server refuses rather than records short.
enum StockAction { stockIn, usage, adjust }

extension StockActionCopy on StockAction {
  String get title => switch (this) {
        StockAction.stockIn => 'Receive Stock',
        StockAction.usage => 'Record Usage',
        StockAction.adjust => 'Adjust Stock',
      };

  String get subtitle => switch (this) {
        StockAction.stockIn => 'Add a delivery to a branch',
        StockAction.usage => 'Log supplies used outside a procedure',
        StockAction.adjust => 'Correct the count after checking the shelf',
      };

  IconData get icon => switch (this) {
        StockAction.stockIn => Icons.add_box_outlined,
        StockAction.usage => Icons.remove_circle_outline,
        StockAction.adjust => Icons.tune_rounded,
      };

  String get quantityLabel => switch (this) {
        StockAction.stockIn => 'Quantity received',
        StockAction.usage => 'Quantity used',
        StockAction.adjust => 'Counted quantity',
      };

  String get quantityHelper => switch (this) {
        StockAction.stockIn => 'How many units arrived',
        StockAction.usage => 'How many units were used',
        // The number on the shelf, not the difference — the difference is what
        // the server works out and records.
        StockAction.adjust => 'The total you counted on the shelf',
      };

  String get submitLabel => switch (this) {
        StockAction.stockIn => 'Receive',
        StockAction.usage => 'Record',
        StockAction.adjust => 'Adjust',
      };

  /// Only a delivery opens a new lot, so only it asks for lot and expiry.
  bool get collectsBatch => this == StockAction.stockIn;

  /// An adjustment asserts that reality disagrees with the ledger, which is
  /// exactly the entry someone will want explained later.
  bool get reasonRequired => this == StockAction.adjust;
}

class StockActionPage extends ConsumerStatefulWidget {
  final StockAction action;

  const StockActionPage({super.key, required this.action});

  @override
  ConsumerState<StockActionPage> createState() => _StockActionPageState();
}

class _StockActionPageState extends ConsumerState<StockActionPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _lotNumber = TextEditingController();
  final _reason = TextEditingController();
  final _notes = TextEditingController();

  int? _branchId;
  int? _itemId;
  DateTime? _expiryDate;
  DateTime? _receivedAt;
  bool _isSubmitting = false;

  StockAction get _action => widget.action;

  @override
  void dispose() {
    _quantity.dispose();
    _lotNumber.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // The dropdowns are not form fields, so validate() cannot see them.
    final branchId = _branchId;
    final itemId = _itemId;

    if (branchId == null || itemId == null) {
      ToastHelper.warning(
        context,
        branchId == null ? 'Choose a branch first.' : 'Choose an item first.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final source = ref.read(stockDataSourceProvider);
    final quantity = int.parse(_quantity.text.trim());

    try {
      final result = switch (_action) {
        StockAction.stockIn => await source.stockIn(
            branchId: branchId,
            itemId: itemId,
            quantity: quantity,
            lotNumber: _lotNumber.text.trim(),
            expiryDate: _asDate(_expiryDate),
            receivedAt: _asDate(_receivedAt),
            reason: _reason.text.trim(),
            notes: _notes.text.trim(),
          ),
        StockAction.usage => await source.recordUsage(
            branchId: branchId,
            itemId: itemId,
            quantity: quantity,
            reason: _reason.text.trim(),
            notes: _notes.text.trim(),
          ),
        StockAction.adjust => await source.adjust(
            branchId: branchId,
            itemId: itemId,
            countedQuantity: quantity,
            reason: _reason.text.trim(),
            notes: _notes.text.trim(),
          ),
      };

      invalidateStock(ref, key: StockKey(branchId: branchId, itemId: itemId));
      await ref.read(inventoryProvider.notifier).refresh();

      if (!mounted) return;

      // A shortfall is not a failure — the supplies are already gone. Saying so
      // plainly beats a success message that hides a negative balance.
      if (result.hasShortfall) {
        ToastHelper.warning(
          context,
          'Recorded, but stock was short by ${result.shortfall}. '
          'The balance is now ${result.balanceAfter}.',
        );
      } else {
        ToastHelper.success(
          context,
          '${_action.title} saved. Balance is now ${result.balanceAfter}.',
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ToastHelper.fromError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  static String? _asDate(DateTime? value) =>
      value?.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    // main.dart still runs ThemeData.dark(); this form is designed light, so
    // it pins the light theme the same way the appointment and schedule forms
    // do — otherwise the text fields, dropdown menus and the date picker
    // inherit dark defaults and render dark-on-dark.
    return Theme(
      data: AppTheme.lightTheme,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_action.title, style: AppTextStyles.titleMedium),
            Text(
              _action.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('Where'),
                  BranchDropdown(
                    value: _branchId,
                    onChanged: (value) => setState(() => _branchId = value),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  ItemDropdown(
                    value: _itemId,
                    onChanged: (value) => setState(() => _itemId = value),
                  ),

                  const SizedBox(height: AppDimensions.paddingLarge),
                  _sectionTitle('How much'),
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: '${_action.quantityLabel} *',
                      helperText: _action.quantityHelper,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());

                      if (parsed == null) {
                        return 'Enter a number.';
                      }
                      // A count of zero is meaningful; receiving or using
                      // nothing is not.
                      if (_action == StockAction.adjust
                          ? parsed < 0
                          : parsed < 1) {
                        return _action == StockAction.adjust
                            ? 'A counted quantity cannot be negative.'
                            : 'Enter at least 1.';
                      }
                      return null;
                    },
                  ),

                  if (_action.collectsBatch) ...[
                    const SizedBox(height: AppDimensions.paddingLarge),
                    _sectionTitle('Batch'),
                    TextFormField(
                      controller: _lotNumber,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Lot number',
                        helperText: 'As printed on the box. Optional.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _DateField(
                      label: 'Expiry date',
                      helper: 'Leave empty for non-perishable stock. '
                          'Earliest expiry is always used first.',
                      value: _expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      onChanged: (date) => setState(() => _expiryDate = date),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _DateField(
                      label: 'Received on',
                      helper: 'Defaults to today. Can be backdated.',
                      value: _receivedAt,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now(),
                      onChanged: (date) => setState(() => _receivedAt = date),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.paddingLarge),
                  _sectionTitle('Why'),
                  TextFormField(
                    controller: _reason,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: _action.reasonRequired ? 'Reason *' : 'Reason',
                      helperText: _action.reasonRequired
                          ? 'The only record of why the count changed.'
                          : 'Optional.',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_action.reasonRequired) return null;

                      return (value ?? '').trim().isEmpty
                          ? 'Give a reason — it is the only record of why the '
                              'count changed.'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingLarge),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_action.icon),
                    label: Text(
                      _isSubmitting ? 'Saving...' : _action.submitLabel,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMedium,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingSmall),
          Text(
            label,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String helper;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.helper,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );

        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today, size: 18)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null
              ? 'Not set'
              : value!.toIso8601String().split('T').first,
          style: AppTextStyles.bodyMedium.copyWith(
            color: value == null ? AppColors.textMuted : null,
          ),
        ),
      ),
    );
  }
}
