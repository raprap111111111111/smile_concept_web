// lib/presentation/providers/user/current_user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/auth/user_model.dart';
import '../auth/auth_provider.dart';

/// Returns the currently authenticated user.
/// Throws if user is not logged in.
///
/// The user is loaded during login / restoreSession, so this is instant.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// Convenience: throws if user is null
final requireUserProvider = Provider<UserModel>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }
  return user;
});