import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/role_repository.dart';
import '../../theme/app_colors.dart';
import 'widgets/permissions_dialog.dart';
import 'widgets/role_card.dart';
import 'widgets/role_delete_dialog.dart';
import 'widgets/role_form_dialog.dart';
import 'widgets/role_search_bar.dart';

class RolesPermissionsPage extends ConsumerStatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  ConsumerState<RolesPermissionsPage> createState() =>
      _RolesPermissionsPageState();
}

class _RolesPermissionsPageState extends ConsumerState<RolesPermissionsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RolesHeader(
              onAdd: () => _openRoleDialog(),
            ),
            const SizedBox(height: 24),
            RoleSearchBar(
              search: _search,
              onChanged: (value) {
                setState(() => _search = value);
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: rolesAsync.when(
                data: (roles) {
                  final filtered = roles.where((role) {
                    final name = role['name']?.toString().toLowerCase() ?? '';
                    final description =
                        role['description']?.toString().toLowerCase() ?? '';
                    final query = _search.toLowerCase().trim();

                    return query.isEmpty ||
                        name.contains(query) ||
                        description.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const RolesEmptyState();
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final role = filtered[index];

                      return RoleCard(
                        role: role,
                        onPermissions: () => _openPermissionsDialog(role),
                        onEdit: () => _openRoleDialog(role: role),
                        onDelete: () => _confirmDelete(role),
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

  Future<void> _openPermissionsDialog(Map<String, dynamic> role) async {
  try {
    final roleId = role['id'] as int;

    // Fetch fresh role details so permissions are included.
    final freshRole = await ref.read(roleRepositoryProvider).getRole(roleId);

    if (!mounted) return;

    debugPrint('FRESH ROLE DATA: $freshRole');
    debugPrint('FRESH ROLE PERMISSIONS: ${freshRole['permissions']}');

    final updatedRole = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionsDialog(role: freshRole),
    );

    if (updatedRole != null) {
      ref.invalidate(rolesProvider);
    }
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to load role permissions: $error'),
      ),
    );
  }
}

  Future<void> _openRoleDialog({
    Map<String, dynamic>? role,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleFormDialog(role: role),
    );

    if (result == null || !mounted) return;

    final repo = ref.read(roleRepositoryProvider);
    final isEdit = role != null;

    try {
      if (isEdit) {
        await repo.updateRole(role['id'] as int, result);
      } else {
        await repo.createRole(result);
      }

      ref.invalidate(rolesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(isEdit ? 'Role updated' : 'Role created'),
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

  Future<void> _confirmDelete(Map<String, dynamic> role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RoleDeleteDialog(role: role),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(roleRepositoryProvider);

      await repo.deleteRole(role['id'] as int);

      ref.invalidate(rolesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('Role deleted'),
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

class RolesHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const RolesHeader({
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
                    Color(0xFF7C3AED),
                    Color(0xFF4F46E5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roles & Permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage user roles and access rights',
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
                Color(0xFF7C3AED),
                Color(0xFF4F46E5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
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
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add Role',
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

class RolesEmptyState extends StatelessWidget {
  const RolesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No roles found',
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
