// lib/presentation/pages/invoices/record_payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../../data/models/invoice/record_payment_request.dart';
import '../../providers/invoice/invoice_provider.dart';
import '../../../core/utils/toast_helper.dart';

class RecordPaymentPage extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const RecordPaymentPage({super.key, required this.invoice});

  @override
  ConsumerState<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends ConsumerState<RecordPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'cash';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.balanceDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final req = RecordPaymentRequest(
      amount: double.parse(_amountController.text),
      paymentMethod: _paymentMethod,
      transactionReference: _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = await ref
        .read(invoiceNotifierProvider.notifier)
        .recordPayment(widget.invoice.id, req);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      ToastHelper.success(context, 'Payment recorded successfully');
      Navigator.pop(context, true);
    } else {
      final err = ref.read(invoiceNotifierProvider).error ?? 'Failed to record payment';
      ToastHelper.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Balance Info ──────────────────────────
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Outstanding Balance', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '₱${NumberFormat('#,##0.00').format(widget.invoice.balanceDue)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Amount ────────────────────────────────
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Invalid amount';
                if (amount > widget.invoice.balanceDue) {
                  return 'Amount exceeds balance due';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Payment Method ────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash',          child: Text('Cash')),
                DropdownMenuItem(value: 'card',          child: Text('Card')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'insurance',     child: Text('Insurance')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),

            const SizedBox(height: 16),

            // ── Reference ─────────────────────────────
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference (optional)',
                hintText: 'e.g., GCash Ref #, Cheque No.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────────
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? 'Processing...' : 'Record Payment'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}