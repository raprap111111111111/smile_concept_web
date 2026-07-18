// lib/presentation/route/routes/protected_routes/invoice_routes.dart

import 'package:go_router/go_router.dart';

import '../../../pages/invoices/invoices_page.dart';
import '../../../pages/invoices/invoice_detail_page.dart';
import '../../route_names.dart';

final List<GoRoute> invoiceRoutes = [
  GoRoute(
    path: '/invoices',
    name: RouteNames.invoices,
    builder: (context, state) => const InvoicesPage(),
    routes: [
      GoRoute(
        path: ':id',
        name: RouteNames.invoiceDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InvoiceDetailPage(invoiceId: id);
        },
      ),
    ],
  ),
];