// lib/presentation/pages/users/users_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/role_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import '../../widgets/shared/search_bar_onclick.dart';
import 'widgets/user_card.dart';
import 'widgets/user_filters.dart';
import 'widgets/user_form_dialog.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _roleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Search ──
  void _onSearch(String value) {
    setState(() => _search = value);
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(staffUsersProvider);
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UsersHeader(onAdd: () => _openUserDialog()),
            const SizedBox(height: AppDimensions.paddingLarge),

            // ── Search Bar (onClick) ──
            SearchBarOnClick(
              controller: _searchController,
              hintText: 'Search users by name or email...',
              onChanged: _onSearch,
              onClear: _onClearSearch,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Role Filter Only (search bypassed) ──
            UserFilters(
              search: _search,
              roleFilter: _roleFilter,
              rolesAsync: rolesAsync,
              onSearchChanged: (_) {
                // No-op — search handled by SearchBarOnClick above
              },
              onRoleChanged: (value) => setState(() => _roleFilter = value),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final filtered = users.where((user) {
                    final name = user['name']?.toString().toLowerCase() ?? '';
                    final email =
                        user['email']?.toString().toLowerCase() ?? '';
                    final query = _search.toLowerCase().trim();
                    final matchesSearch = query.isEmpty ||
                        name.contains(query) ||
                        email.contains(query);
                    final roleNames = _extractRoleNames(user['roles']);
                    final matchesRole =
                        _roleFilter == null || roleNames.contains(_roleFilter);
                    return matchesSearch && matchesRole;
                  }).toList();

                  if (filtered.isEmpty) return const UsersEmptyState();

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisSpacing: AppDimensions.paddingMedium,
                      crossAxisSpacing: AppDimensions.paddingMedium,
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
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => _ErrorView(message: error.toString()),
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
      if (role is Map && role['name'] != null) return role['name'].toString();
      return role.toString();
    }).toList();
  }

  Future<void> _openUserDialog({Map<String, dynamic>? user}) async {
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
      _showSnack(
        isEdit ? 'User updated successfully' : 'User created successfully',
        AppColors.success,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Error: $error', AppColors.error);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final name = user['name']?.toString() ?? 'this user';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? '';

    final userInfo = [
      if (email.isNotEmpty) email,
      if (role.isNotEmpty) 'Role: $role',
    ].join(' • ');

    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete User',
      itemName: name,
      description: 'You are about to permanently delete the user "$name"'
          '${userInfo.isNotEmpty ? '\n\n$userInfo' : ''}\n\n'
          'This will revoke their access immediately and remove all '
          'associated permissions. This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.deleteUser(user['id'] as int);
      ref.invalidate(staffUsersProvider);
      if (!mounted) return;
      _showSnack('"$name" deleted', AppColors.success);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Error: $error', AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class UsersHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const UsersHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: AppDimensions.iconBadgeSize,
              height: AppDimensions.iconBadgeSize,
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.people_rounded,
                color: AppColors.primary,
                size: AppDimensions.iconSize,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Users Management', style: AppTextStyles.titleLarge),
                Text(
                  'Manage staff accounts, roles, and access',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(
            Icons.add_rounded,
            size: AppDimensions.iconSizeSmall,
          ),
          label: Text(
            'Add User',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class UsersEmptyState extends StatelessWidget {
  const UsersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.06),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
              border: Border.all(
                color: AppColors.primaryWithOpacity(0.12),
              ),
            ),
            child: const Icon(
              Icons.people_rounded,
              size: 38,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('No users found', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'No staff accounts match your current filters.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Something went wrong', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}