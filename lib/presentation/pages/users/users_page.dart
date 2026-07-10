import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/role_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../theme/app_colors.dart';
import 'widgets/user_card.dart';
import 'widgets/user_delete_dialog.dart';
import 'widgets/user_filters.dart';
import 'widgets/user_form_dialog.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  String _search = '';
  String? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(staffUsersProvider);
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UsersHeader(
              onAdd: () => _openUserDialog(),
            ),
            const SizedBox(height: 24),
            UserFilters(
              search: _search,
              roleFilter: _roleFilter,
              rolesAsync: rolesAsync,
              onSearchChanged: (value) {
                setState(() => _search = value);
              },
              onRoleChanged: (value) {
                setState(() => _roleFilter = value);
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final filtered = users.where((user) {
                    final name = user['name']?.toString().toLowerCase() ?? '';
                    final email = user['email']?.toString().toLowerCase() ?? '';
                    final query = _search.toLowerCase().trim();

                    final matchesSearch = query.isEmpty ||
                        name.contains(query) ||
                        email.contains(query);

                    final roleNames = _extractRoleNames(user['roles']);

                    final matchesRole =
                        _roleFilter == null || roleNames.contains(_roleFilter);

                    return matchesSearch && matchesRole;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const UsersEmptyState();
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];

                      return UserCard(
                        user: user,
                        onEdit: () => _openUserDialog(user: user),
                        onDelete: () => _confirmDelete(user),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractRoleNames(dynamic roles) {
    if (roles is! List) return [];

    return roles.map<String>((role) {
      if (role is Map && role['name'] != null) {
        return role['name'].toString();
      }

      return role.toString();
    }).toList();
  }

  Future<void> _openUserDialog({
    Map<String, dynamic>? user,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(user: user),
    );

    if (result == null || !mounted) return;

    final repo = ref.read(userRepositoryProvider);
    final isEdit = user != null;

    try {
      if (isEdit) {
        await repo.updateUser(user['id'] as int, result);
      } else {
        await repo.createUser(result);
      }

      ref.invalidate(staffUsersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(isEdit ? 'User updated' : 'User created'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: $error'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => UserDeleteDialog(user: user),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(userRepositoryProvider);

      await repo.deleteUser(user['id'] as int);

      ref.invalidate(staffUsersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('User deleted'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: $error'),
        ),
      );
    }
  }
}

class UsersHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const UsersHeader({
    super.key,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF06B6D4),
                    Color(0xFF3B82F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage staff accounts, roles, and access',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF06B6D4),
                Color(0xFF3B82F6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onAdd,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add User',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UsersEmptyState extends StatelessWidget {
  const UsersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
