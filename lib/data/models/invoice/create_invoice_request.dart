// lib/data/models/invoice/create_invoice_request.dart

class CreateInvoiceItemRequest {
  final int treatmentId;
  final int quantity;
  final double discount;

  const CreateInvoiceItemRequest({
    required this.treatmentId,
    required this.quantity,
    this.discount = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'treatment_id': treatmentId,
        'quantity': quantity,
        'discount': discount,
      };
}

class CreateInvoiceRequest {
  final int appointmentId;
  final List<CreateInvoiceItemRequest> items;

  const CreateInvoiceRequest({
    required this.appointmentId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'appointment_id': appointmentId,
        'items': items.map((i) => i.toJson()).toList(),
      };
}