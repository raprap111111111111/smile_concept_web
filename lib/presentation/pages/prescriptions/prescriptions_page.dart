// lib/presentation/pages/prescriptions/prescriptions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/prescription/prescription_provider.dart';
import '../../route/route_names.dart'; // ✅ ADD THIS
import 'widgets/prescription_card.dart';
import 'widgets/prescription_empty_state.dart';

class PrescriptionsPage extends ConsumerStatefulWidget {
  final int? patientId;

  const PrescriptionsPage({super.key, this.patientId});

  @override
  ConsumerState<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends ConsumerState<PrescriptionsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load({bool forceRefresh = false}) {
    ref.read(prescriptionProvider.notifier).loadPrescriptions(
          patientId: widget.patientId,
          forceRefresh: forceRefresh,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(prescriptionProvider.notifier).loadMore();
    }
  }

  void _openDetail(int prescriptionId) {
    context.pushNamed(
      RouteNames.prescriptionDetail,
      pathParameters: {'id': prescriptionId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.prescriptionCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Prescription'),
      ),
    );
  }

  Widget _buildBody(PrescriptionState state) {
    // ── Loading ──────────────────────────────────────────────
    if (state.isListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Error ────────────────────────────────────────────────
    if (state.hasListError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.listError ?? 'Failed to load prescriptions',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _load(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ────────────────────────────────────────────────
    if (state.isEmpty) {
      return PrescriptionEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    // ── List ─────────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(prescriptionProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount:
            state.prescriptions.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more spinner at bottom
          if (index == state.prescriptions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final prescription = state.prescriptions[index];

          return PrescriptionCard(
            prescription: prescription,
            onTap: () => _openDetail(prescription.id),
          );
        },
      ),
    );
  }
}