// lib/presentation/pages/invoices/invoices_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/invoice/invoice_provider.dart';
import 'invoice_detail_page.dart';
import 'widgets/invoice_card.dart';

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> {
  final _scrollController = ScrollController();

  static const _statuses = [
    (label: 'All',       value: null),
    (label: 'Unpaid',    value: 'unpaid'),
    (label: 'Partial',   value: 'partial'),
    (label: 'Paid',      value: 'paid'),
    (label: 'Cancelled', value: 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceNotifierProvider.notifier).load(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(invoiceNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceNotifierProvider);
    final notifier = ref.read(invoiceNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: notifier.refresh),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips ─────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final item = _statuses[index];
                final isSelected = state.filter.status == item.value;

                return FilterChip(
                  label: Text(item.label),
                  selected: isSelected,
                  onSelected: (_) => notifier.applyFilter(
                    item.value == null
                        ? state.filter.copyWith(clearStatus: true)
                        : state.filter.copyWith(status: item.value),
                  ),
                  showCheckmark: false,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(InvoiceListState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: ref.read(invoiceNotifierProvider.notifier).refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No invoices found.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: ref.read(invoiceNotifierProvider.notifier).refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.invoices.length + (state.hasNextPage ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.invoices.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final invoice = state.invoices[i];
          return InvoiceCard(
            invoice: invoice,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailPage(invoiceId: invoice.id),
              ),
            ),
          );
        },
      ),
    );
  }
}