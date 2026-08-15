// lib/presentation/providers/inventory/inventory_form_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/inventory/inventory_branch_model.dart';
import '../../../data/models/inventory/inventory_item_model.dart';

/// Picker lists for the inventory forms.
///
/// Both are `autoDispose`. As plain FutureProviders they resolved once and
/// cached for the rest of the session, so a form opened while the catalog was
/// still empty kept reporting "no items available" no matter how many items
/// were added afterwards — the only thing that refetched was the Retry button,
/// which only appears on error. Dropping the cache when no form is watching
/// means every picker opens against current data.
///
/// Both also send `limit`, not `per_page`. The endpoints validate `limit` and
/// strip anything they do not recognise, so `per_page` was discarded and the
/// lists silently fell back to the defaults — 15 items and 10 branches.

// ── Branches simple list ───────────────────────────────────────
/// Branches this user can actually act on.
///
/// `mine=1` narrows the list to their branch memberships. Stock reads and
/// writes are scoped server-side, so an unscoped picker would offer branches
/// whose stock comes back empty and whose writes come back 403 — a choice that
/// only ever leads to a dead end.
///
/// Only inventory uses this provider; the schedules page has its own, which
/// still lists every branch because booking legitimately spans them.
final branchesSimpleListProvider =
    FutureProvider.autoDispose<List<InventoryBranchModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(
    '/branches',
    queryParameters: {'limit': 100, 'mine': 1},
  );

  final data = response.data['data'] as Map<String, dynamic>;
  // ✅ Your API uses 'records', not 'data'
  final list = data['records'] as List<dynamic>? ?? [];

  return list
      .map((e) =>
          InventoryBranchModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Items simple list ──────────────────────────────────────────
final itemsSimpleListProvider =
    FutureProvider.autoDispose<List<InventoryItemModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(
    '/items',
    queryParameters: {'limit': 100},
  );

  final data = response.data['data'] as Map<String, dynamic>;
  // ✅ Your API uses 'records', not 'data'
  final list = data['records'] as List<dynamic>? ?? [];

  return list
      .map((e) =>
          InventoryItemModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
