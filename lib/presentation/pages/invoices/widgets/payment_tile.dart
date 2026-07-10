// lib/presentation/pages/invoices/widgets/payment_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/invoice/payment_model.dart';

class PaymentTile extends StatelessWidget {
  final PaymentModel payment;

  const PaymentTile({super.key, required this.payment});

  IconData _methodIcon() {
    switch (payment.paymentMethod) {
      case 'cash':          return Icons.payments;
      case 'card':          return Icons.credit_card;
      case 'bank_transfer': return Icons.account_balance;
      case 'insurance':     return Icons.health_and_safety;
      default:              return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: Icon(_methodIcon(), color: Colors.green.shade700),
      ),
      title: Text(
        '₱${NumberFormat('#,##0.00').format(payment.amount)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(payment.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 11)),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(payment.paymentDate),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (payment.transactionReference != null)
            Text('Ref: ${payment.transactionReference}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}