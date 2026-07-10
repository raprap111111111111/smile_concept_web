// lib/data/repositories/invoice_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/invoice_remote_datasource.dart';
import '../models/invoice/invoice_model.dart';
import '../models/invoice/create_invoice_request.dart';
import '../models/invoice/record_payment_request.dart';
import '../models/invoice/paginated_invoice_result.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(invoiceRemoteDataSourceProvider));
});

class InvoiceRepository {
  final InvoiceRemoteDataSource _remote;
  InvoiceRepository(this._remote);

  Future<PaginatedInvoiceResult> getInvoices({
    int page = 1,
    int pageSize = 20,
    String? status,
    int? appointmentId,
  }) =>
      _remote.getInvoices(
        page: page,
        pageSize: pageSize,
        status: status,
        appointmentId: appointmentId,
      );

  Future<InvoiceModel> getInvoice(int id) => _remote.getInvoice(id);

  Future<InvoiceModel> createInvoice(CreateInvoiceRequest req) =>
      _remote.createInvoice(req);

  Future<InvoiceModel> recordPayment(int invoiceId, RecordPaymentRequest req) =>
      _remote.recordPayment(invoiceId, req);
}