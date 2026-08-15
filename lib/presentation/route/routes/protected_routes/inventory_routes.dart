// lib/presentation/route/routes/protected_routes/inventory_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../pages/inventory/inventory_detail_page.dart';
import '../../../pages/inventory/inventory_page.dart';
import '../../../pages/inventory/inventory_form_page.dart';
import '../../../pages/inventory/inventory_settings_page.dart';
import '../../../pages/inventory/items_page.dart';
import '../../../pages/inventory/item_form_page.dart';
import '../../../pages/inventory/stock_action_page.dart';
import '../../../pages/inventory/transfer_stock_page.dart';
import '../../route_names.dart';
import '../../page_transitions.dart';

/// A non-numeric `:id` is a bad URL, not a crash.
///
/// These used to call `int.parse` directly, which throws out of a route builder
/// and takes the shell down with it. go_router's error page is the right
/// answer, and returning a 404-ish screen gets us there.
Widget _withIntId(String? raw, Widget Function(int) build) {
  final id = int.tryParse(raw ?? '');

  if (id == null) {
    return const Scaffold(
      body: Center(child: Text('That page address is not valid.')),
    );
  }

  return build(id);
}

final List<GoRoute> inventoryRoutes = [
  // ── Inventory ─────────────────────────────────────────────
  GoRoute(
    path: '/inventory',
    name: RouteNames.inventory,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const InventoryPage(),
    ),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.inventoryCreate,
        builder: (context, state) => const InventoryFormPage(),
      ),

      // ── Stock movements ───────────────────────────────
      // Literal segments, so they must be declared before ':id'.
      GoRoute(
        path: 'stock-in',
        name: RouteNames.inventoryStockIn,
        builder: (context, state) =>
            const StockActionPage(action: StockAction.stockIn),
      ),
      GoRoute(
        path: 'usage',
        name: RouteNames.inventoryUsage,
        builder: (context, state) =>
            const StockActionPage(action: StockAction.usage),
      ),
      GoRoute(
        path: 'adjust',
        name: RouteNames.inventoryAdjust,
        builder: (context, state) =>
            const StockActionPage(action: StockAction.adjust),
      ),
      GoRoute(
        path: 'transfer',
        name: RouteNames.inventoryTransfer,
        builder: (context, state) => const TransferStockPage(),
      ),

      GoRoute(
        path: ':id/edit',
        name: RouteNames.inventoryEdit,
        builder: (context, state) => _withIntId(
          state.pathParameters['id'],
          (id) => InventoryFormPage(inventoryId: id),
        ),
      ),
      // Finally gives RouteNames.inventoryDetail — a dead constant until now —
      // something to point at.
      GoRoute(
        path: ':id',
        name: RouteNames.inventoryDetail,
        builder: (context, state) => _withIntId(
          state.pathParameters['id'],
          (id) => InventoryDetailPage(inventoryId: id),
        ),
      ),
    ],
  ),

  // ── Inventory settings ────────────────────────────────────
  GoRoute(
    path: '/inventory-settings',
    name: RouteNames.inventorySettings,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const InventorySettingsPage(),
    ),
  ),

  // ── Items ─────────────────────────────────────────────────
  GoRoute(
    path: '/items',
    name: RouteNames.items,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const ItemsPage(),
    ),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.itemCreate,
        builder: (context, state) => const ItemFormPage(),
      ),
      GoRoute(
        path: ':id/edit',
        name: RouteNames.itemEdit,
        builder: (context, state) => _withIntId(
          state.pathParameters['id'],
          (id) => ItemFormPage(itemId: id),
        ),
      ),
    ],
  ),
];
