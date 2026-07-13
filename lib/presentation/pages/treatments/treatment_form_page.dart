// lib/presentation/pages/treatments/treatment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/treatment/treatment_provider.dart';

class TreatmentFormPage extends ConsumerStatefulWidget {
  final int? treatmentId;

  const TreatmentFormPage({
    super.key,
    this.treatmentId,
  });

  @override
  ConsumerState<TreatmentFormPage> createState() =>
      _TreatmentFormPageState();
}

class _TreatmentFormPageState
    extends ConsumerState<TreatmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isSubmitting = false;
  bool get _isEditing => widget.treatmentId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price =
          double.tryParse(_priceController.text.trim()) ?? 0.0;
      final duration =
          int.tryParse(_durationController.text.trim()) ?? 30;

      if (_isEditing) {
        await ref.read(treatmentProvider.notifier).updateTreatment(
              id: widget.treatmentId!,
              name: name,
              description: description,
              price: price,
              estimatedDurationMinutes: duration, // ✅ FIXED
            );
      } else {
        await ref.read(treatmentProvider.notifier).createTreatment(
              name: name,
              description: description,
              price: price,
              estimatedDurationMinutes: duration, // ✅ FIXED
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Treatment updated successfully'
                  : 'Treatment created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Treatment' : 'New Treatment'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Treatment Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Treatment name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '₱ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Price is required';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                      suffixText: 'min',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null &&
                          v.trim().isNotEmpty &&
                          int.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isEditing
                      ? 'Update Treatment'
                      : 'Create Treatment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}