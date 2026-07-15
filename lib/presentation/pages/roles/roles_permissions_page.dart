import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/role_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
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
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          RolesHeader(onAdd: () => _openRoleDialog()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoleSearchBar(
                    search: _search,
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  Expanded(
                    child: rolesAsync.when(
                      data: (roles) {
                        final filtered = roles.where((role) {
                          final name =
                              role['name']?.toString().toLowerCase() ?? '';
                          final desc = role['description']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          final q = _search.toLowerCase().trim();
                          return q.isEmpty ||
                              name.contains(q) ||
                              desc.contains(q);
                        }).toList();

                        if (filtered.isEmpty) return const RolesEmptyState();

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
                              onPermissions: () =>
                                  _openPermissionsDialog(role),
                              onEdit: () => _openRoleDialog(role: role),
                              onDelete: () => _confirmDelete(role),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Text(
                          'Error: $error',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPermissionsDialog(Map<String, dynamic> role) async {
    try {
      final roleId = role['id'] as int;
      final freshRole =
          await ref.read(roleRepositoryProvider).getRole(roleId);

      if (!mounted) return;

      final updatedRole = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PermissionsDialog(role: freshRole),
      );

      if (updatedRole != null) ref.invalidate(rolesProvider);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Failed to load role permissions: $error', isError: true);
    }
  }

  Future<void> _openRoleDialog({Map<String, dynamic>? role}) async {
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
      _showSnack(isEdit ? 'Role updated' : 'Role created', isError: false);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Error: $error', isError: true);
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
      _showSnack('Role deleted', isError: false);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Error: $error', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════
class RolesHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const RolesHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.22),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roles & Permissions',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage user roles and access rights',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Role'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════
class RolesEmptyState extends StatelessWidget {
  const RolesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.22),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 48,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No roles found',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or create a new role.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}