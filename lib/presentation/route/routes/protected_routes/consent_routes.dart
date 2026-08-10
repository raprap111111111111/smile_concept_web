import 'package:go_router/go_router.dart';

import '/presentation/pages/consent/consent_detail_page.dart';
import '/presentation/pages/consent/my_consents_page.dart';
import '/presentation/route/route_names.dart';
import '/presentation/route/page_transitions.dart';

final List<GoRoute> consentRoutes = [
  GoRoute(
    path: '/consents',
    name: RouteNames.consents,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const MyConsentsPage(),
    ),
    routes: [
      GoRoute(
        path: ':id',
        name: 'consent-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return FadeThroughPage(
            key: state.pageKey,
            child: ConsentDetailPage(consentId: id),
          );
        },
      ),
    ],
  ),
];