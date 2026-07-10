import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';

class UserFilters extends StatelessWidget {
  final String search;
  final String? roleFilter;
  final AsyncValue<List<Map<String, dynamic>>> rolesAsync;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleChanged;

  const UserFilters({
    super.key,
    required this.search,
    required this.roleFilter,
    required this.rolesAsync,
    required this.onSearchChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white38,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: rolesAsync.when(
              data: (roles) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: roleFilter,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceDark,
                    hint: const Text(
                      'All Roles',
                      style: TextStyle(color: Colors.white38),
                    ),
                    icon: const Icon(
                      Icons.filter_list,
                      color: Colors.white54,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Roles',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ...roles.map((role) {
                        final name = role['name']?.toString() ?? '';

                        return DropdownMenuItem<String?>(
                          value: name,
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                    onChanged: onRoleChanged,
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text(
                'Failed to load roles',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
