import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoleSearchBar extends StatelessWidget {
  final String search;
  final ValueChanged<String> onChanged;

  const RoleSearchBar({
    super.key,
    required this.search,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search roles...',
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
    );
  }
}
