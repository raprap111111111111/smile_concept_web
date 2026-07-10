// lib/presentation/pages/invoices/widgets/invoice_item_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/invoice/invoice_item_model.dart';

class InvoiceItemTile extends StatelessWidget {
  final InvoiceItemModel item;

  const InvoiceItemTile({super.key, required this.item});

  String _money(double v) => '₱${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(
        item.treatmentName ?? 'Treatment #${item.treatmentId}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${item.quantity} × ${_money(item.unitPrice)}'
        '${item.discount > 0 ? "  •  Discount: ${_money(item.discount)}" : ""}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        _money(item.totalPrice),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}