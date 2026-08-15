// lib/presentation/providers/inventory/inventory_form_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/inventory/inventory_branch_model.dart';
import '../../../data/models/inventory/inventory_item_model.dart';

// ── Branches simple list ───────────────────────────────────────
/// Branches this user can actually act on.
///
/// `mine=1` narrows the list to their branch memberships. Stock reads and
/// writes are scoped server-side, so an unscoped picker would offer branches
/// whose stock comes back empty and whose writes come back 403 — a pill that
/// only ever leads to a dead end.
///
/// Only inventory uses this provider; the schedules page has its own, which
/// still lists every branch because booking legitimately spans them.
final branchesSimpleListProvider =
    FutureProvider<List<InventoryBranchModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(
    '/branches',
    queryParameters: {'per_page': 100, 'mine': 1},
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
    FutureProvider<List<InventoryItemModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(
    '/items',
    queryParameters: {'per_page': 100},
  );

  final data = response.data['data'] as Map<String, dynamic>;
  // ✅ Your API uses 'records', not 'data'
  final list = data['records'] as List<dynamic>? ?? [];

  return list
      .map((e) =>
          InventoryItemModel.fromJson(e as Map<String, dynamic>))
      .toList();
});