// lib/data/models/invoice/payment_model.dart

class PaymentModel {
  final int id;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? transactionReference;
  final String? notes;

  const PaymentModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.transactionReference,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int? ?? 0,
      amount: _asDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentDate: DateTime.tryParse(json['payment_date']?.toString() ?? '') ?? DateTime.now(),
      transactionReference: json['transaction_reference']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}