import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/permission_repository.dart';
import '../../../../data/repositories/role_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class PermissionsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> role;

  const PermissionsDialog({super.key, required this.role});

  @override
  ConsumerState<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends ConsumerState<PermissionsDialog> {
  late Set<String> _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selected = _extractPermissionNames(widget.role['permissions']);
  }

  Set<String> _extractPermissionNames(dynamic permissions) {
    if (permissions is! List) return <String>{};
    return permissions.map<String>((p) {
      if (p is Map && p['name'] != null) return p['name'].toString();
      return p.toString();
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(permissionsGroupedProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: permissionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $error',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                ),
                data: (grouped) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    children: grouped.entries.map((entry) {
                      return _PermissionGroup(
                        resource: entry.key,
                        permissions: entry.value,
                        selected: _selected,
                        onChanged: () => setState(() {}),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.line)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
          topRight: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.22),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.security_outlined,
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
                  widget.role['name']?.toString() ?? '',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage permissions for this role',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.22),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.accentWithOpacity(0.5)),
            ),
            child: Text(
              '${_selected.length} selected',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ─── Footer ────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.line)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.borderRadiusLarge),
          bottomRight: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
                side: const BorderSide(color: AppColors.line),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(roleRepositoryProvider);
      final updatedRole = await repo.syncPermissions(
        widget.role['id'] as int,
        _selected.toList(),
      );

      ref.invalidate(rolesProvider);
      if (!mounted) return;
      Navigator.pop(context, updatedRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permissions updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Permission group (expandable card)
// ═══════════════════════════════════════════════════════════
class _PermissionGroup extends StatelessWidget {
  final String resource;
  final List permissions;
  final Set<String> selected;
  final VoidCallback onChanged;

  const _PermissionGroup({
    required this.resource,
    required this.permissions,
    required this.selected,
    required this.onChanged,
  });

  String _permName(dynamic p) {
    if (p is Map && p['name'] != null) return p['name'].toString();
    return p.toString();
  }

  @override
  Widget build(BuildContext context) {
    final names = permissions.map(_permName).toList();
    final allSelected =
        names.isNotEmpty && names.every((n) => selected.contains(n));
    final someSelected = names.any((n) => selected.contains(n));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: AppColors.primaryDark,
          collapsedIconColor: AppColors.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Checkbox(
                value: allSelected
                    ? true
                    : someSelected
                        ? null
                        : false,
                tristate: true,
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                side: const BorderSide(
                    color: AppColors.textSecondary, width: 1.5),
                onChanged: (value) {
                  if (value == true) {
                    selected.addAll(names);
                  } else {
                    selected.removeAll(names);
                  }
                  onChanged();
                },
              ),
              Expanded(
                child: Text(
                  resource.toUpperCase().replaceAll('-', ' '),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentWithOpacity(0.22),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(
                    color: AppColors.accentWithOpacity(0.5),
                  ),
                ),
                child: Text(
                  '${permissions.length}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: permissions.map((permission) {
                  final name = _permName(permission);
                  final active = selected.contains(name);

                  return InkWell(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                    onTap: () {
                      if (active) {
                        selected.remove(name);
                      } else {
                        selected.add(name);
                      }
                      onChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentWithOpacity(0.22)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.line,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 14,
                            color: active
                                ? AppColors.primaryDark
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name.split('.').last,
                            style: TextStyle(
                              color: active
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}