// lib/data/models/invoice/paginated_invoice_result.dart

import 'invoice_model.dart';

class PaginatedInvoiceResult {
  final List<InvoiceModel> data;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const PaginatedInvoiceResult({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  });
}