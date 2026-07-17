// lib/presentation/providers/auth/auth_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/auth/user_model.dart';

// ─── Auth Status ──────────────────────────────────────────────
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

// ─── Auth State ───────────────────────────────────────────────
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  // ── Status helpers ─────────────────────────────────────────
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isInitial => status == AuthStatus.initial;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => errorMessage != null;

  // ── Delegate role to UserModel ─────────────────────────────
  // These all use UserModel's existing logic — no duplication
  String get role => user?.role ?? 'guest';

  bool get isSuperAdmin => user?.isSuperAdmin ?? false;
  bool get isAdmin => role == 'admin';
  bool get isDentist => role == 'dentist';
  bool get isReceptionist => role == 'receptionist';
  bool get isPatient => role == 'patient';
  bool get isStaff => isSuperAdmin || isAdmin || isDentist || isReceptionist;

  // ── Delegate permission checks to UserModel ────────────────
  // UserModel.can() already handles super-admin bypass
  bool hasPermission(String permission) => user?.can(permission) ?? false;

  bool hasAnyPermission(List<String> perms) => user?.canAny(perms) ?? false;

  bool hasAllPermissions(List<String> perms) => user?.canAll(perms) ?? false;

  // ── Prescription shortcuts ─────────────────────────────────
  // From seeder: dentist → create/update/delete/print/send
  //              admin   → viewAny/view/print only
  //              patient → view only
  bool get canViewPrescriptions => hasAnyPermission([
        'prescription.viewAny',
        'prescription.view',
      ]);

  bool get canCreatePrescription => hasPermission('prescription.create');

  bool get canUpdatePrescription => hasPermission('prescription.update');

  bool get canDeletePrescription => hasPermission('prescription.delete');

  bool get canPrintPrescription => hasPermission('prescription.print');

  bool get canSendPrescription => hasPermission('prescription.send');

  // ── copyWith ───────────────────────────────────────────────
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage, // intentionally nullable
    );
  }

  AuthState toUnauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  @override
  String toString() => 'AuthState('
      'status: $status, '
      'role: $role, '
      'permissions: ${user?.permissions.length ?? 0}, '
      'user: ${user?.email}'
      ')';
}

// ─── Provider ─────────────────────────────────────────────────
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository);
});

// ─── Notifier ─────────────────────────────────────────────────
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AuthState());

  // ─── Restore Session ────────────────────────────────────────
  Future<void> restoreSession() async {
    print('════════════════════════════════════════════');
    print('🎬 restoreSession() STARTED');
    print('════════════════════════════════════════════');

    if (state.status != AuthStatus.initial) {
      print('⏭️ Already checked — skipping');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    final hasSession = await _authRepository.hasValidSession();
    print('🔑 hasValidSession: $hasSession');

    if (!hasSession) {
      print('❌ No token → unauthenticated');
      state = state.toUnauthenticated();
      return;
    }

    print('✅ Token exists → fetching profile');

    try {
      final user = await _authRepository.getProfile();

      // ── Log for debugging ──────────────────────────────────
      print('✅ User loaded: ${user.name}');
      print('👤 Role: ${user.role}');
      print('🔐 Permissions: ${user.permissions.length}');
      if (user.permissions.isNotEmpty) {
        final prescriptionPerms = user.permissions
            .where((p) => p.startsWith('prescription'))
            .toList();
        print('💊 Prescription perms: $prescriptionPerms');
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      print('⚠️ Profile fetch error: $e');

      final errorStr = e.toString().toLowerCase();
      final isUnauthorized =
          errorStr.contains('401') || errorStr.contains('unauthorized');

      if (isUnauthorized) {
        print('🚨 401 → clearing session');
        await _authRepository.clearSession();
        state = state.toUnauthenticated();
      } else {
        // ✅ On network/server errors, treat as unauthenticated
        print('🌐 Network/server error → unauthenticated');
        await _authRepository.clearSession();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Unable to connect. Please try again.',
        );
      }
    }
  }

  // ─── Login ──────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );

    try {
      final response = await _authRepository.login(email, password);
      final user = response.user;

      // ── Debug log ──────────────────────────────────────────
      print('✅ Login: ${user?.name} | role: ${user?.role}');
      print('🔐 Permissions: ${user?.permissions.length ?? 0}');

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
    }
  }

  // ─── Register ───────────────────────────────────────────────
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

      print('✅ Registration successful');
      print('User: ${response.user}');

      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } on DioException catch (e) {
      print('Status Code: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
    } catch (e) {
      print('❌ Registration failed');
      print(e);

      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
    }
  }

  // ─── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      await _authRepository.clearSession();
    } finally {
      state = state.toUnauthenticated();
    }
  }

  // ─── Refresh profile & permissions ──────────────────────────
  Future<void> refreshProfile() async {
    try {
      final user = await _authRepository.getProfile();
      state = state.copyWith(user: user);
      print('🔄 Profile refreshed: '
          '${user.permissions.length} permissions, '
          'role: ${user.role}');
    } catch (e) {
      print('⚠️ Failed to refresh profile: $e');
    }
  }

  // ─── Helper ─────────────────────────────────────────────────
  String _parseError(Object e) =>
      e.toString().replaceAll('Exception: ', '').replaceAll('ApiFailure: ', '');
}
