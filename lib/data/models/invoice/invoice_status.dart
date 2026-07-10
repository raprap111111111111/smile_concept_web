// lib/data/models/invoice/invoice_status.dart

import 'package:flutter/material.dart';

enum InvoiceStatus {
  unpaid,
  partial,
  paid,
  cancelled,
}

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.unpaid:    return 'Unpaid';
      case InvoiceStatus.partial:   return 'Partial';
      case InvoiceStatus.paid:      return 'Paid';
      case InvoiceStatus.cancelled: return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.unpaid:    return Colors.orange;
      case InvoiceStatus.partial:   return Colors.blue;
      case InvoiceStatus.paid:      return Colors.green;
      case InvoiceStatus.cancelled: return Colors.grey;
    }
  }

  static InvoiceStatus fromString(String? value) {
    switch (value) {
      case 'partial':   return InvoiceStatus.partial;
      case 'paid':      return InvoiceStatus.paid;
      case 'cancelled': return InvoiceStatus.cancelled;
      default:          return InvoiceStatus.unpaid;
    }
  }
}