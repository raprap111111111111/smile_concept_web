// lib/presentation/providers/inventory/stock_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/datasources/remote/stock_remote_datasource.dart';
import '../../../data/models/inventory/inventory_batch_model.dart';
import '../../../data/models/inventory/stock_movement_model.dart';

final stockDataSourceProvider = Provider<StockRemoteDataSource>((ref) {
  return StockRemoteDataSource(dio: ref.read(dioProvider));
});

/// Which stock row a detail view is looking at.
///
/// Batches and movements are both keyed on branch + item rather than on the
/// summary row's id, because that is how the ledger and the lots are keyed
/// server-side.
class StockKey {
  final int branchId;
  final int itemId;

  const StockKey({required this.branchId, required this.itemId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockKey &&
          other.branchId == branchId &&
          other.itemId == itemId);

  @override
  int get hashCode => Object.hash(branchId, itemId);
}

/// Open lots for one stock row, earliest expiry first — the order consumption
/// will actually draw them in.
final stockBatchesProvider = FutureProvider.autoDispose
    .family<List<InventoryBatchModel>, StockKey>((ref, key) async {
  return ref.read(stockDataSourceProvider).fetchBatches(
        branchId: key.branchId,
        itemId: key.itemId,
      );
});

/// Movement history for one stock row, newest first.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovementModel>, StockKey>((ref, key) async {
  return ref.read(stockDataSourceProvider).fetchMovements(
        branchId: key.branchId,
        itemId: key.itemId,
      );
});

/// Clinic-wide ledger, for the movements page.
final recentMovementsProvider =
    FutureProvider.autoDispose<List<StockMovementModel>>((ref) async {
  return ref.read(stockDataSourceProvider).fetchMovements();
});

/// Refetch everything a stock write could have changed.
///
/// Called after any of the four verbs, so a detail view open behind the form
/// does not keep showing pre-write numbers.
///
/// Takes a `WidgetRef` rather than a `Ref`: Riverpod 2 gives the two no shared
/// supertype, and every caller here is a screen. The dashboard splits its
/// refresh helpers for the same reason.
void invalidateStock(WidgetRef ref, {StockKey? key}) {
  ref.invalidate(recentMovementsProvider);

  if (key != null) {
    ref.invalidate(stockBatchesProvider(key));
    ref.invalidate(stockMovementsProvider(key));
  }
}
