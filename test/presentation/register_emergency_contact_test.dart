// The emergency contact section on signup is optional and starts collapsed,
// so the fields must be reachable by expanding it and must not block submit
// when left empty.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smile_concept_web/presentation/pages/auth/register_page.dart';

Future<void> pumpRegisterPage(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/login', builder: (_, __) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // The auth provider chain reaches ApiConfig, which reads dotenv.
    dotenv.testLoad(
      fileInput: 'ENVIRONMENT=testing\nAPI_BASE_URL=http://localhost/api/v1',
    );
  });

  testWidgets('the section is collapsed but expandable', (tester) async {
    tester.view.physicalSize = const Size(500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpRegisterPage(tester);

    expect(find.text('Emergency contact'), findsOneWidget);
    expect(find.text('Optional — you can add this later'), findsOneWidget);

    // Collapsed: the tile hasn't built its children at all.
    expect(find.text('Contact name', skipOffstage: false), findsNothing);

    await tester.tap(find.text('Emergency contact'));
    await tester.pumpAndSettle();

    expect(find.text('Contact name'), findsOneWidget);
    expect(find.text('Contact phone'), findsOneWidget);
  });

  testWidgets('a bad phone hidden in the collapsed section still surfaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpRegisterPage(tester);

    await tester.tap(find.text('Emergency contact'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '+1234567890').last,
      '123',
    );
    await tester.tap(find.text('Emergency contact'));
    await tester.pumpAndSettle();
    expect(find.text('Contact phone', skipOffstage: false), findsNothing);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Contact phone'), findsOneWidget);
    expect(find.text('Please enter a valid phone number'), findsOneWidget);
  });

  testWidgets('an empty emergency contact does not block validation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpRegisterPage(tester);

    final formState = tester.state<FormState>(find.byType(Form));
    formState.validate();
    await tester.pump();

    // Only the required fields complain; nothing from the optional section.
    expect(find.text('Please enter a valid phone number'), findsNothing);
  });
}
