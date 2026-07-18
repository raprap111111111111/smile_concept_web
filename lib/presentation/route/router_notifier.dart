// lib/presentation/route/router_notifier.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth/auth_provider.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        debugPrint('[Router] Auth changed: ${previous?.status} → ${next.status}');
        notifyListeners();
      },
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}