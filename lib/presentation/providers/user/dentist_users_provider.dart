// lib/presentation/providers/user/dentist_users_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/user_repository.dart';

/// Fetches all users with the 'dentist' role.
/// Used by the doctor form dialog to select a user to link to a doctor profile.
///
/// Declared at the top level so Riverpod treats it as the same provider
/// across rebuilds (avoids infinite fetch loops).
final dentistUsersProvider = FutureProvider.autoDispose(
  (ref) => ref.read(userRepositoryProvider).getStaffUsers(role: 'dentist'),
);