// lib/presentation/route/routes/protected_routes/inventory_routes.dart

import 'package:go_router/go_router.dart';

import '../../../pages/inventory/inventory_page.dart';
import '../../../pages/inventory/inventory_form_page.dart';
import '../../../pages/inventory/items_page.dart';
import '../../../pages/inventory/item_form_page.dart';
import '../../route_names.dart';

final List<GoRoute> inventoryRoutes = [
  // ── Inventory ─────────────────────────────────────────────
  GoRoute(
    path: '/inventory',
    name: RouteNames.inventory,
    builder: (context, state) => const InventoryPage(),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.inventoryCreate,
        builder: (context, state) => const InventoryFormPage(),
      ),
      GoRoute(
        path: ':id/edit',
        name: RouteNames.inventoryEdit,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);

          return InventoryFormPage(
            inventoryId: id,
          );
        },
      ),
    ],
  ),

  // ── Items ─────────────────────────────────────────────────
  GoRoute(
    path: '/items',
    name: RouteNames.items,
    builder: (context, state) => const ItemsPage(),
    routes: [
      GoRoute(
        path: 'new',
        name: RouteNames.itemCreate,
        builder: (context, state) => const ItemFormPage(),
      ),
      GoRoute(
        path: ':id/edit',
        name: RouteNames.itemEdit,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);

          return ItemFormPage(
            itemId: id,
          );
        },
      ),
    ],
  ),
];