// lib/presentation/pages/inventory/transfer_stock_page.dart

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

/// Moves stock between branches, lot by lot.
///
/// Separate from [StockActionPage] because it names two branches, and because
/// it is the one outflow the server refuses outright: usage records supplies
/// already gone, but a transfer is a promise about the future and cannot ship
/// what is not on the shelf.
class TransferStockPage extends ConsumerStatefulWidget {
  const TransferStockPage({super.key});

  @override
  ConsumerState<TransferStockPage> createState() => _TransferStockPageState();
}

class _TransferStockPageState extends ConsumerState<TransferStockPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  final _notes = TextEditingController();

  int? _fromBranchId;
  int? _toBranchId;
  int? _itemId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final from = _fromBranchId;
    final to = _toBranchId;
    final itemId = _itemId;

    if (from == null || to == null || itemId == null) {
      ToastHelper.warning(
        context,
        'Choose a source branch, a destination and an item.',
      );
      return;
    }

    if (from == to) {
      ToastHelper.warning(context, 'Pick a different destination branch.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ref.read(stockDataSourceProvider).transfer(
            fromBranchId: from,
            toBranchId: to,
            itemId: itemId,
            quantity: int.parse(_quantity.text.trim()),
            reason: _reason.text.trim(),
            notes: _notes.text.trim(),
          );

      invalidateStock(ref, key: StockKey(branchId: from, itemId: itemId));
      invalidateStock(ref, key: StockKey(branchId: to, itemId: itemId));
      await ref.read(inventoryProvider.notifier).refresh();

      if (!mounted) return;

      final source = result['source']?['balance_after'];
      final destination = result['destination']?['balance_after'];

      ToastHelper.success(
        context,
        'Transferred. Source is now $source, destination $destination.',
      );

      Navigator.of(context).pop();
    } catch (e) {
      // Includes the 409 for insufficient stock, whose message names the
      // branch and how far short it was.
      if (mounted) ToastHelper.fromError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // main.dart still runs ThemeData.dark(); this form is designed light, so
    // it pins the light theme the same way the appointment and schedule forms
    // do — otherwise the text fields and dropdown menus inherit dark defaults
    // and render dark-on-dark.
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
            const Text('Transfer Stock', style: AppTextStyles.titleMedium),
            Text(
              'Move supplies between branches',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
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
                  _sectionTitle('From'),
                  BranchDropdown(
                    value: _fromBranchId,
                    onChanged: (value) =>
                        setState(() => _fromBranchId = value),
                  ),

                  const SizedBox(height: AppDimensions.paddingLarge),
                  _sectionTitle('To'),
                  BranchDropdown(
                    value: _toBranchId,
                    onChanged: (value) => setState(() => _toBranchId = value),
                  ),
                  if (_fromBranchId != null &&
                      _fromBranchId == _toBranchId) ...[
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      'Stock cannot transfer to itself.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.paddingLarge),
                  _sectionTitle('What'),
                  ItemDropdown(
                    value: _itemId,
                    onChanged: (value) => setState(() => _itemId = value),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      helperText:
                          'Lots move earliest-expiry-first, keeping their '
                          'lot number and expiry.',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());

                      if (parsed == null) return 'Enter a number.';
                      if (parsed < 1) return 'Enter at least 1.';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimensions.paddingLarge),
                  _sectionTitle('Why'),
                  TextFormField(
                    controller: _reason,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      helperText: 'Optional.',
                      border: OutlineInputBorder(),
                    ),
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
                        : const Icon(Icons.swap_horiz),
                    label: Text(_isSubmitting ? 'Transferring...' : 'Transfer'),
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
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
