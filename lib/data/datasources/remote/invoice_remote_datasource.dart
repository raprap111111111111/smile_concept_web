// lib/data/datasources/remote/invoice_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../models/invoice/invoice_model.dart';
import '../../models/invoice/create_invoice_request.dart';
import '../../models/invoice/record_payment_request.dart';
import '../../models/invoice/paginated_invoice_result.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

final invoiceRemoteDataSourceProvider = Provider<InvoiceRemoteDataSource>((ref) {
  return InvoiceRemoteDataSource(ref.watch(dioProvider));
});

class InvoiceRemoteDataSource {
  final Dio _dio;
  InvoiceRemoteDataSource(this._dio);

  static const String _base = '/invoices';

  Future<PaginatedInvoiceResult> getInvoices({
    int page = 1,
    int pageSize = 20,
    String? status,
    int? appointmentId,
  }) async {
    try {
      final response = await _dio.get(_base, queryParameters: {
        'page': page,
        'limit': pageSize,
        if (status != null) 'status': status,
        if (appointmentId != null) 'appointment_id': appointmentId,
      });

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final List items = data['records'] as List? ?? [];

      return PaginatedInvoiceResult(
        data: items
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: data['total'] ?? 0,
        currentPage: data['current_page'] ?? page,
        lastPage: data['last_page'] ?? 1,
        hasNextPage: data['has_more'] ?? false,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InvoiceModel> getInvoice(int id) async {
    try {
      final response = await _dio.get('$_base/$id');
      return InvoiceModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InvoiceModel> createInvoice(CreateInvoiceRequest req) async {
    try {
      final response = await _dio.post(_base, data: req.toJson());
      return InvoiceModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InvoiceModel> recordPayment(int invoiceId, RecordPaymentRequest req) async {
    try {
      final response = await _dio.post(
        '$_base/$invoiceId/payments',
        data: req.toJson(),
      );
      return InvoiceModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Status handling now lives in `describeError`, which turns 401/403/404 into
  /// sentences instead of the "Unauthorized: <server text>" prefixes this used
  /// to emit, and reads the whole validation bag rather than one field.
  Exception _handleError(DioException e) => Exception(
        describeError(e, fallback: "That invoice request didn't go through. "
            'Please try again.'),
      );
}