// lib/presentation/pages/inventory/item_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/inventory/item_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  final int? itemId;

  const ItemFormPage({
    super.key,
    this.itemId,
  });

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _thresholdController = TextEditingController(text: '10');

  String? _selectedCategory;
  String? _selectedUnit;
  bool _isSubmitting = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.itemId != null;

  static const _categories = [
    'PPE',
    'Restorative',
    'Anesthetics',
    'Endodontics',
    'Orthodontics',
    'Surgical',
    'Impression',
    'Hygiene',
    'Lab Materials',
    'General',
  ];

  static const _units = [
    'piece',
    'box',
    'bottle',
    'pack',
    'tube',
    'roll',
    'set',
    'pair',
    'sachet',
    'cartridge',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadItem());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // ── Load existing item for edit ────────────────────────────
  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(itemProvider.notifier)
          .loadById(widget.itemId!); // ← needs loadById in ItemNotifier

      final item = ref.read(itemProvider).selected;
      if (item != null && mounted) {
        setState(() {
          _nameController.text      = item.name;
          _skuController.text       = item.sku;
          _selectedCategory         = item.category;
          _selectedUnit             = item.unitOfMeasure;
          _thresholdController.text = item.minimumThreshold.toString();
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to load item: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await ref.read(itemProvider.notifier).updateItem(
              id: widget.itemId!,
              name: _nameController.text.trim(),
              sku: _skuController.text.trim(),
              category: _selectedCategory!,
              unitOfMeasure: _selectedUnit!,
              minimumThreshold:
                  int.tryParse(_thresholdController.text.trim()) ?? 10,
            );
      } else {
        await ref.read(itemProvider.notifier).createItem(
              name: _nameController.text.trim(),
              sku: _skuController.text.trim(),
              category: _selectedCategory!,
              unitOfMeasure: _selectedUnit!,
              minimumThreshold:
                  int.tryParse(_thresholdController.text.trim()) ?? 10,
            );
      }

      if (mounted) {
        _showSnack(
          _isEditMode
              ? 'Item updated successfully'
              : 'Item created successfully',
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

  // ── Snackbar helper ────────────────────────────────────────
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
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
          _isEditMode ? 'Edit Item' : 'New Item',
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
              icon: const Icon(
                Icons.save,
                size: AppDimensions.iconSizeSmall,
              ),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.all(AppDimensions.paddingLarge),
                children: [
                  _sectionTitle('Item Details'),
                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Name ──────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    style: AppTextStyles.bodyMedium,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      prefixIcon:
                          Icon(Icons.medical_services_outlined),
                      hintText: 'e.g., Dental Cement, Latex Gloves',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── SKU ───────────────────────────────────
                  TextFormField(
                    controller: _skuController,
                    style: AppTextStyles.bodyMedium,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'SKU *',
                      prefixIcon: Icon(Icons.qr_code_outlined),
                      hintText: 'e.g., DC-100, LG-200',
                      helperText: 'Unique stock keeping unit code',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'SKU is required'
                            : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Category ──────────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    hint: Text(
                      'Select category',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v),
                    validator: (v) =>
                        v == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Unit of Measure ───────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    isExpanded: true,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Unit of Measure *',
                      prefixIcon: Icon(Icons.straighten_outlined),
                    ),
                    hint: Text(
                      'Select unit',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                    items: _units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedUnit = v),
                    validator: (v) =>
                        v == null ? 'Unit is required' : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),

                  // ── Min Threshold ─────────────────────────
                  TextFormField(
                    controller: _thresholdController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Threshold',
                      prefixIcon:
                          Icon(Icons.warning_amber_outlined),
                      helperText:
                          'Alert when stock falls below this number',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null &&
                          v.isNotEmpty &&
                          int.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // ── Submit Button ─────────────────────────
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
                          : const Icon(
                              Icons.save,
                              size: AppDimensions.iconSizeSmall,
                            ),
                      label: Text(
                        _isEditMode
                            ? 'Update Item'
                            : 'Create Item',
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius,
                          ),
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
          style: AppTextStyles.labelLarge
              .copyWith(color: AppColors.primaryDark),
        ),
      ],
    );
  }
}