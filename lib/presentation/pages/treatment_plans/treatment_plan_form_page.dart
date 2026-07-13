// lib/presentation/pages/treatment_plans/treatment_plan_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/treatment/treatment_provider.dart';
import '../../../data/models/treatment/treatment_model.dart';

// ─── Plan Item State ─────────────────────────────────────────────────────────
class _PlanItemForm {
  TreatmentModel? selectedTreatment;
  final TextEditingController notesController = TextEditingController();
  int quantity = 1;

  double get price => selectedTreatment?.price ?? 0.0;
  double get subtotal => price * quantity;

  void dispose() {
    notesController.dispose();
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────
class TreatmentPlanFormPage extends ConsumerStatefulWidget {
  final int? patientId;
  final int? doctorId;

  const TreatmentPlanFormPage({
    super.key,
    this.patientId,
    this.doctorId,
  });

  @override
  ConsumerState<TreatmentPlanFormPage> createState() =>
      _TreatmentPlanFormPageState();
}

class _TreatmentPlanFormPageState
    extends ConsumerState<TreatmentPlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedDoctorId;
  int? _selectedPatientId;
  bool _isSubmitting = false;

  final List<_PlanItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedDoctorId = widget.doctorId;
    _addItem();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load treatments (this one we know exists)
      ref.read(treatmentProvider.notifier).loadTreatments();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_PlanItemForm()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double get _grandTotal =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      _showSnack('Add at least one treatment item', Colors.red);
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      if (_items[i].selectedTreatment == null) {
        _showSnack('Select a treatment for Item ${i + 1}', Colors.red);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Wire up to your create plan API call here

      if (mounted) {
        _showSnack('Treatment plan created', Colors.green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treatmentState = ref.watch(treatmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Treatment Plan'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Plan Name ─────────────────────────────────────
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
                hintText: 'e.g. John\'s Dental Restoration',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Patient ID (temp text field until we know provider) ──
            TextFormField(
              initialValue: _selectedPatientId?.toString(),
              decoration: const InputDecoration(
                labelText: 'Patient ID *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Enter patient ID',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  _selectedPatientId = int.tryParse(v),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Doctor ID (temp text field until we know provider) ──
            TextFormField(
              initialValue: _selectedDoctorId?.toString(),
              decoration: const InputDecoration(
                labelText: 'Doctor ID *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
                hintText: 'Enter doctor ID',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  _selectedDoctorId = int.tryParse(v),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Treatment Items ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Treatment Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!treatmentState.isListLoading &&
                treatmentState.treatments.isEmpty)
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No treatments in catalog. Please '
                          'create treatments first from the '
                          '"Treatments" page.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _PlanItemFormWidget(
                index: index,
                item: item,
                availableTreatments: treatmentState.treatments,
                isLoading: treatmentState.isListLoading,
                onRemove: _items.length > 1
                    ? () => _removeItem(index)
                    : null,
                onChanged: () => setState(() {}),
              );
            }),

            const SizedBox(height: 16),

            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₱${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan Item Widget ────────────────────────────────────────────────────────
class _PlanItemFormWidget extends StatelessWidget {
  final int index;
  final _PlanItemForm item;
  final List<TreatmentModel> availableTreatments;
  final bool isLoading;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _PlanItemFormWidget({
    required this.index,
    required this.item,
    required this.availableTreatments,
    required this.isLoading,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    tooltip: 'Remove item',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Treatment Dropdown ────────────────────────────
            DropdownButtonFormField<TreatmentModel>(
              initialValue: item.selectedTreatment, // ✅ FIXED
              decoration: const InputDecoration(
                labelText: 'Treatment *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              isExpanded: true,
              hint: isLoading
                  ? const Text('Loading...')
                  : const Text('Select treatment from catalog'),
              items: availableTreatments
                  .map((t) => DropdownMenuItem<TreatmentModel>(
                        value: t,
                        child: Text(
                          '${t.name} (₱${t.price.toStringAsFixed(2)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                item.selectedTreatment = v;
                onChanged();
              },
              validator: (v) =>
                  v == null ? 'Select a treatment' : null,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                        'price-${item.selectedTreatment?.id}'),
                    initialValue: item.price.toStringAsFixed(2),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₱ ',
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      item.quantity = int.tryParse(v) ?? 1;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: ₱${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: item.notesController,
              decoration: const InputDecoration(
                labelText: 'Item Notes',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}