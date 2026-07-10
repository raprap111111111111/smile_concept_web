// lib/data/models/invoice/invoice_model.dart

import 'invoice_status.dart';
import 'invoice_item_model.dart';
import 'payment_model.dart';

class InvoiceModel {
  final int id;
  final int appointmentId;
  final double totalAmount;
  final double balanceDue;
  final InvoiceStatus status;
  final List<InvoiceItemModel> items;
  final List<PaymentModel> payments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InvoiceModel({
    required this.id,
    required this.appointmentId,
    required this.totalAmount,
    required this.balanceDue,
    required this.status,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ✅ Derived properties
  double get amountPaid => totalAmount - balanceDue;
  bool get isPaid => status == InvoiceStatus.paid;
  bool get canRecordPayment =>
      status == InvoiceStatus.unpaid || status == InvoiceStatus.partial;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: _asInt(json['id']),
      appointmentId: _asInt(json['appointment_id']),
      totalAmount: _asDouble(json['total_amount']),
      balanceDue: _asDouble(json['balance_due']),
      status: InvoiceStatusX.fromString(json['status']?.toString()),
      items: (json['items'] as List? ?? [])
          .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  InvoiceModel copyWith({
    InvoiceStatus? status,
    double? balanceDue,
    List<PaymentModel>? payments,
  }) {
    return InvoiceModel(
      id: id,
      appointmentId: appointmentId,
      totalAmount: totalAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      items: items,
      payments: payments ?? this.payments,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is double) return v.toInt();
    return 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}