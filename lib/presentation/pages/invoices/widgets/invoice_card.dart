// lib/presentation/pages/invoices/widgets/invoice_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/invoice/invoice_model.dart';
import 'invoice_status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  String _money(double v) => '₱${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invoice #${invoice.id.toString().padLeft(5, "0")}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  InvoiceStatusBadge(status: invoice.status),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                'Appointment #${invoice.appointmentId}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              const Divider(height: 20),

              Row(
                children: [
                  _StatBlock(label: 'Total',   value: _money(invoice.totalAmount)),
                  _StatBlock(label: 'Paid',    value: _money(invoice.amountPaid), color: Colors.green),
                  _StatBlock(label: 'Balance', value: _money(invoice.balanceDue), color: invoice.balanceDue > 0 ? Colors.red : Colors.green),
                ],
              ),

              if (invoice.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Issued: ${DateFormat('MMM dd, yyyy').format(invoice.createdAt!)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatBlock({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}