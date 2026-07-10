// lib/data/models/invoice/invoice_item_model.dart

class InvoiceItemModel {
  final int id;
  final int treatmentId;
  final String? treatmentName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double totalPrice;

  const InvoiceItemModel({
    required this.id,
    required this.treatmentId,
    this.treatmentName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.totalPrice,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: _asInt(json['id']),
      treatmentId: _asInt(json['treatment_id']),
      treatmentName: json['treatment_name']?.toString(),
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      discount: _asDouble(json['discount']),
      totalPrice: _asDouble(json['total_price']),
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