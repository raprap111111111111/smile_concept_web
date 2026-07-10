// lib/data/datasources/remote/invoice_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../models/invoice/invoice_model.dart';
import '../../models/invoice/create_invoice_request.dart';
import '../../models/invoice/record_payment_request.dart';
import '../../models/invoice/paginated_invoice_result.dart';

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

  Exception _handleError(DioException e) {
    final code = e.response?.statusCode;
    final message = e.response?.data?['message'] ?? e.message ?? 'Unknown error';

    switch (code) {
      case 401: return Exception('Unauthorized: $message');
      case 403: return Exception('Forbidden: $message');
      case 404: return Exception('Not found: $message');
      case 422:
        final errors = e.response?.data?['errors'];
        if (errors != null) {
          final firstError = (errors as Map).values.first;
          return Exception(firstError is List ? firstError.first : firstError.toString());
        }
        return Exception(message);
      default: return Exception(message);
    }
  }
}