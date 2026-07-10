// lib/presentation/providers/invoice/invoice_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../../data/models/invoice/create_invoice_request.dart';
import '../../../data/models/invoice/record_payment_request.dart';
import '../../../data/repositories/invoice_repository.dart';

// ─── Filter ─────────────────────────────────────────────────
class InvoiceFilter {
  final String? status;
  final int? appointmentId;

  const InvoiceFilter({this.status, this.appointmentId});

  InvoiceFilter copyWith({
    String? status,
    int? appointmentId,
    bool clearStatus = false,
    bool clearAppointmentId = false,
  }) {
    return InvoiceFilter(
      status: clearStatus ? null : status ?? this.status,
      appointmentId: clearAppointmentId ? null : appointmentId ?? this.appointmentId,
    );
  }
}

// ─── State ──────────────────────────────────────────────────
class InvoiceListState {
  final List<InvoiceModel> invoices;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasNextPage;
  final InvoiceFilter filter;

  const InvoiceListState({
    this.invoices = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasNextPage = false,
    this.filter = const InvoiceFilter(),
  });

  InvoiceListState copyWith({
    List<InvoiceModel>? invoices,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasNextPage,
    InvoiceFilter? filter,
    bool clearError = false,
  }) {
    return InvoiceListState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      filter: filter ?? this.filter,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────
class InvoiceNotifier extends StateNotifier<InvoiceListState> {
  final InvoiceRepository _repository;

  InvoiceNotifier(this._repository) : super(const InvoiceListState());

  Future<void> load({bool reset = false}) async {
    if (reset) {
      state = state.copyWith(
        isLoading: true,
        invoices: [],
        currentPage: 1,
        clearError: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final result = await _repository.getInvoices(
        page: state.currentPage,
        status: state.filter.status,
        appointmentId: state.filter.appointmentId,
      );

      state = state.copyWith(
        invoices: reset ? result.data : [...state.invoices, ...result.data],
        hasNextPage: result.hasNextPage,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isLoadingMore: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasNextPage) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await load();
  }

  Future<void> refresh() => load(reset: true);

  void applyFilter(InvoiceFilter filter) {
    state = state.copyWith(filter: filter);
    load(reset: true);
  }

  void addInvoice(InvoiceModel invoice) {
    state = state.copyWith(invoices: [invoice, ...state.invoices]);
  }

  void updateInvoice(InvoiceModel updated) {
    state = state.copyWith(
      invoices: state.invoices
          .map((i) => i.id == updated.id ? updated : i)
          .toList(),
    );
  }

  Future<InvoiceModel?> createInvoice(CreateInvoiceRequest req) async {
    try {
      final invoice = await _repository.createInvoice(req);
      addInvoice(invoice);
      return invoice;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<InvoiceModel?> recordPayment(int invoiceId, RecordPaymentRequest req) async {
    try {
      final invoice = await _repository.recordPayment(invoiceId, req);
      updateInvoice(invoice);
      return invoice;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

// ─── Providers ──────────────────────────────────────────────
final invoiceNotifierProvider =
    StateNotifierProvider<InvoiceNotifier, InvoiceListState>((ref) {
  return InvoiceNotifier(ref.watch(invoiceRepositoryProvider));
});

// Single invoice detail
final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel, int>((ref, id) {
  return ref.watch(invoiceRepositoryProvider).getInvoice(id);
});