import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/permission_repository.dart';
import '../../../../data/repositories/role_repository.dart';
import '../../../theme/app_colors.dart';

class PermissionsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> role;

  const PermissionsDialog({
    super.key,
    required this.role,
  });

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

    debugPrint('ROLE: ${widget.role['name']}');
    debugPrint('ROLE PERMISSIONS RAW: ${widget.role['permissions']}');
    debugPrint('SELECTED PERMISSIONS: $_selected');
  }

  Set<String> _extractPermissionNames(dynamic permissions) {
    if (permissions is! List) return <String>{};

    return permissions.map<String>((permission) {
      if (permission is Map && permission['name'] != null) {
        return permission['name'].toString();
      }

      return permission.toString();
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(permissionsGroupedProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: permissionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                data: (grouped) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
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
                  );
                },
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.security,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role['name']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Manage permissions for this role',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              disabledBackgroundColor:
                  const Color(0xFF7C3AED).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('Permissions updated'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: $error'),
        ),
      );
    }
  }
}

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

  String _permissionName(dynamic permission) {
    if (permission is Map && permission['name'] != null) {
      return permission['name'].toString();
    }

    return permission.toString();
  }

  @override
  Widget build(BuildContext context) {
    final permissionNames = permissions.map(_permissionName).toList();

    final allSelected = permissionNames.isNotEmpty &&
        permissionNames.every((name) => selected.contains(name));

    final someSelected = permissionNames.any(
      (name) => selected.contains(name),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Checkbox(
                value: allSelected
                    ? true
                    : someSelected
                        ? null
                        : false,
                tristate: true,
                activeColor: const Color(0xFF7C3AED),
                onChanged: (value) {
                  if (value == true) {
                    selected.addAll(permissionNames);
                  } else {
                    selected.removeAll(permissionNames);
                  }

                  onChanged();
                },
              ),
              Expanded(
                child: Text(
                  resource.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${permissions.length}',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: permissions.map((permission) {
                  final permissionName = _permissionName(permission);
                  final active = selected.contains(permissionName);

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (active) {
                        selected.remove(permissionName);
                      } else {
                        selected.add(permissionName);
                      }

                      onChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF7C3AED)
                              : Colors.white.withValues(alpha: 0.1),
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
                                ? const Color(0xFF7C3AED)
                                : Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            permissionName.split('.').last,
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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