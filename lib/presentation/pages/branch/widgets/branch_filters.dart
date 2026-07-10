import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class BranchFilters extends StatelessWidget {
  final String search;
  final bool? activeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool?> onActiveFilterChanged;

  const BranchFilters({
    super.key,
    required this.search,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onActiveFilterChanged,
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
                hintText: 'Search by name, code, city, or province...',
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
        _filterChip(
          label: 'All',
          active: activeFilter == null,
          onTap: () => onActiveFilterChanged(null),
        ),
        const SizedBox(width: 8),
        _filterChip(
          label: 'Active',
          active: activeFilter == true,
          onTap: () => onActiveFilterChanged(true),
        ),
        const SizedBox(width: 8),
        _filterChip(
          label: 'Inactive',
          active: activeFilter == false,
          onTap: () => onActiveFilterChanged(false),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? const Color(0xFF10B981).withValues(alpha: 0.2)
          : AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? const Color(0xFF10B981)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF10B981) : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}