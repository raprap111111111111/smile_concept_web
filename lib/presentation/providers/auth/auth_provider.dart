// lib/presentation/providers/auth/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/auth/user_model.dart';

// ─── Auth Status ──────────────────────────────────────────────────────────────
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

// ─── Auth State ───────────────────────────────────────────────────────────────
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isInitial => status == AuthStatus.initial;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  AuthState toUnauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email}, error: $errorMessage)';
}

// ─── Auth Provider ────────────────────────────────────────────────────────────
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository);
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AuthState());

  // ─── Restore Session on App Start ─────────────────────────────
  // lib/presentation/providers/auth/auth_provider.dart

  // lib/presentation/providers/auth/auth_provider.dart

  Future<void> restoreSession() async {
    print('════════════════════════════════════════════');
    print('🎬 restoreSession() STARTED');
    print('════════════════════════════════════════════');

    if (state.status != AuthStatus.initial) {
      print('⏭️ Already checked — skipping');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    // Check token exists
    final hasSession = await _authRepository.hasValidSession();
    print('🔑 hasValidSession: $hasSession');

    if (!hasSession) {
      print('No token → unauthenticated');
      state = state.toUnauthenticated();
      return;
    }

    print('✅ Token exists → fetching /auth/users/me');

    // Try to load user — DO NOT clear session on any failure except explicit 401
    try {
      final user = await _authRepository.getProfile();
      print('✅ User: ${user.name} (${user.role})');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      print('⚠️ Profile fetch/parse error: $e');

      final errorStr = e.toString().toLowerCase();
      final isUnauthorized =
          errorStr.contains('401') || errorStr.contains('unauthorized');

      if (isUnauthorized) {
        print('🚨 Server said 401 → clearing session');
        await _authRepository.clearSession();
        state = state.toUnauthenticated();
      } else {
        print('✋ Not 401 — keeping user logged in (user data will be null)');
        // Stay authenticated, just no user object
        state = const AuthState(
          status: AuthStatus.authenticated,
          user: null,
        );
      }
    }
  }

  // ─── Login ────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _authRepository.login(email, password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user, // may be null — that's OK
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
    }
  }

  // ─── Register ─────────────────────────────────────────────────
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );

    try {
      final response = await _authRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
    }
  }

  // ─── Logout ───────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      await _authRepository.clearSession();
    } finally {
      state = state.toUnauthenticated();
    }
  }

  String _parseError(Object e) =>
      e.toString().replaceAll('Exception: ', '').replaceAll('ApiFailure: ', '');
}
