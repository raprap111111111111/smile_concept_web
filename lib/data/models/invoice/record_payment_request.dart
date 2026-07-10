// lib/data/models/invoice/record_payment_request.dart

class RecordPaymentRequest {
  final double amount;
  final String paymentMethod; // cash, card, bank_transfer, insurance
  final String? paymentDate;
  final String? transactionReference;
  final String? notes;

  const RecordPaymentRequest({
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.transactionReference,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'payment_method': paymentMethod,
        if (paymentDate != null) 'payment_date': paymentDate,
        if (transactionReference != null)
          'transaction_reference': transactionReference,
        if (notes != null) 'notes': notes,
      };
}