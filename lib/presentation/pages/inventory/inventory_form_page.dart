// lib/presentation/pages/inventory/inventory_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/inventory/inventory_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/branch_dropdown.dart';
import 'widgets/item_dropdown.dart';

class InventoryFormPage extends ConsumerStatefulWidget {
  final int? inventoryId;

  const InventoryFormPage({super.key, this.inventoryId});

  @override
  ConsumerState<InventoryFormPage> createState() =>
      _InventoryFormPageState();
}

class _InventoryFormPageState extends ConsumerState<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  int? _selectedBranchId;
  int? _selectedItemId;
  DateTime? _expiryDate;

  bool _isSubmitting = false;
  bool _isLoading = false;

  bool get _isEditing => widget.inventoryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadInventory());
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    await ref
        .read(inventoryProvider.notifier)
        .loadById(widget.inventoryId!);

    final inv = ref.read(inventoryProvider).selected;
    if (inv != null && mounted) {
      setState(() {
        _selectedBranchId = inv.branchId;
        _selectedItemId = inv.itemId;
        _quantityController.text = inv.quantity.toString();
        if (inv.expiryDate != null) {
          _expiryDate = DateTime.tryParse(inv.expiryDate!);
        }
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.background,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final quantity =
          int.tryParse(_quantityController.text.trim()) ?? 0;
      final expiryDateStr = _expiryDate != null
          ? _expiryDate!.toIso8601String().split('T').first
          : null;

      if (_isEditing) {
        await ref.read(inventoryProvider.notifier).updateInventory(
              id: widget.inventoryId!,
              branchId: _selectedBranchId!,
              itemId: _selectedItemId!,
              quantity: quantity,
              expiryDate: expiryDateStr,
            );
      } else {
        await ref.read(inventoryProvider.notifier).createInventory(
              branchId: _selectedBranchId!,
              itemId: _selectedItemId!,
              quantity: quantity,
              expiryDate: expiryDateStr,
            );
      }

      if (mounted) {
        _showSnack(
          _isEditing
              ? 'Inventory updated successfully'
              : 'Inventory added successfully',
          AppColors.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          _isEditing ? 'Edit Inventory' : 'Add Inventory',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: SizedBox(
                width: AppDimensions.iconSizeSmall,
                height: AppDimensions.iconSizeSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save,
                  size: AppDimensions.iconSizeSmall),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(
                    AppDimensions.paddingLarge),
                children: [
                  // ── Section: Stock Details ─────────
                  _sectionTitle('Stock Details'),

                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Branch Dropdown ────────────────
                  BranchDropdown(
                    value: _selectedBranchId,
                    onChanged: (val) =>
                        setState(() => _selectedBranchId = val),
                  ),

                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Item Dropdown ──────────────────
                  ItemDropdown(
                    value: _selectedItemId,
                    onChanged: (val) =>
                        setState(() => _selectedItemId = val),
                  ),

                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Quantity ───────────────────────
                  TextFormField(
                    controller: _quantityController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      prefixIcon: Icon(Icons.numbers),
                      helperText: 'Amount in stock',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      final qty = int.tryParse(v.trim());
                      if (qty == null || qty < 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Expiry Date ────────────────────
                  InkWell(
                    onTap: _pickExpiryDate,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (optional)',
                        prefixIcon: const Icon(
                            Icons.calendar_today_outlined),
                        suffixIcon: _expiryDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: AppDimensions
                                        .iconSizeSmall),
                                onPressed: () => setState(
                                    () => _expiryDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _expiryDate != null
                            ? _expiryDate!
                                .toIso8601String()
                                .split('T')
                                .first
                            : 'No expiry date set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _expiryDate != null
                              ? AppColors.text
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // ── Submit Button ──────────────────
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.save,
                              size: AppDimensions.iconSizeSmall),
                      label: Text(
                        _isEditing
                            ? 'Update Inventory'
                            : 'Add Inventory',
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}