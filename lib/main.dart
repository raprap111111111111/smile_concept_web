// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/api_config.dart';
import 'presentation/route/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
    ApiConfig.printConfig();
  } catch (e) {
    print('''
⚠️  Warning: Could not load .env file
   Reason: $e
   
   Fix:
   1. Create a .env file in project root
   2. Copy from .env.example: cp .env.example .env
   3. Set your backend URL inside
   4. Restart the app
''');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'SmileConcept',
      theme: ThemeData.dark(),
    );
  }
}