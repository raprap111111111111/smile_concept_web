// lib/presentation/pages/treatments/treatments_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/../core/permissions/app_permissions.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/treatment/treatment_provider.dart';
import '../../route/route_names.dart';
import 'widgets/treatment_card.dart';
import 'widgets/treatment_empty_state.dart';

class TreatmentsPage extends ConsumerStatefulWidget {
  const TreatmentsPage({super.key});

  @override
  ConsumerState<TreatmentsPage> createState() =>
      _TreatmentsPageState();
}

class _TreatmentsPageState extends ConsumerState<TreatmentsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load({bool forceRefresh = false}) {
    ref
        .read(treatmentProvider.notifier)
        .loadTreatments(forceRefresh: forceRefresh);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(treatmentProvider.notifier).loadMore();
    }
  }

  Future<void> _delete(int id, String name) async {
    final auth = ref.read(authStateProvider);
    if (!auth.hasPermission(Perm.treatmentDelete)) {
      _showSnack('No permission to delete treatments', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Treatment?'),
        content:
            Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(treatmentProvider.notifier)
        .deleteTreatment(id);

    if (!mounted) return;
    _showSnack(
      success
          ? 'Treatment deleted'
          : ref.read(treatmentProvider).listError ??
              'Failed to delete',
      success ? Colors.green : Colors.red,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentProvider);
    final auth = ref.watch(authStateProvider);

    final canCreate = auth.hasPermission(Perm.treatmentCreate);
    final canDelete = auth.hasPermission(Perm.treatmentDelete);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatments Catalog'),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(state, canDelete),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.pushNamed(RouteNames.treatmentCreate),
              icon: const Icon(Icons.add),
              label: const Text('New Treatment'),
            )
          : null,
    );
  }

  Widget _buildBody(TreatmentState state, bool canDelete) {
    if (state.isListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasListError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.listError ?? 'Error',
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

    if (state.isEmpty) {
      return TreatmentEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(treatmentProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.treatments.length +
            (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.treatments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child:
                  Center(child: CircularProgressIndicator()),
            );
          }
          final t = state.treatments[index];
          return TreatmentCard(
            treatment: t,
            canDelete: canDelete,
            onDelete: () => _delete(t.id, t.name),
          );
        },
      ),
    );
  }
}