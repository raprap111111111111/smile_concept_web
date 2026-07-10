// lib/presentation/pages/invoices/invoice_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice/invoice_provider.dart';
import '../../../data/models/invoice/invoice_model.dart';
import 'record_payment_page.dart';
import 'widgets/invoice_status_badge.dart';
import 'widgets/invoice_item_tile.dart';
import 'widgets/payment_tile.dart';

class InvoiceDetailPage extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  String _money(double v) => '₱${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInvoice = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoiceId.toString().padLeft(5, "0")}'),
      ),
      body: asyncInvoice.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoice) => _buildBody(context, ref, invoice),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, InvoiceModel invoice) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary Card ────────────────────────────
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment #${invoice.appointmentId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    InvoiceStatusBadge(status: invoice.status),
                  ],
                ),
                const Divider(height: 24),
                _row('Total Amount', _money(invoice.totalAmount)),
                const SizedBox(height: 6),
                _row('Amount Paid',  _money(invoice.amountPaid), color: Colors.green),
                const SizedBox(height: 6),
                _row(
                  'Balance Due',
                  _money(invoice.balanceDue),
                  color: invoice.balanceDue > 0 ? Colors.red : Colors.green,
                  bold: true,
                ),
                if (invoice.canRecordPayment) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecordPaymentPage(invoice: invoice),
                          ),
                        );
                        if (ok == true) {
                          ref.invalidate(invoiceDetailProvider(invoiceId));
                        }
                      },
                      icon: const Icon(Icons.payments),
                      label: const Text('Record Payment'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Items ───────────────────────────────────
        _sectionTitle('Items (${invoice.items.length})'),
        Card(
          child: Column(
            children: invoice.items.map((i) => InvoiceItemTile(item: i)).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // ── Payments ────────────────────────────────
        _sectionTitle('Payments (${invoice.payments.length})'),
        if (invoice.payments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No payments recorded yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: invoice.payments.map((p) => PaymentTile(payment: p)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}