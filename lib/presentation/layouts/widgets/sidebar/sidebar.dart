// lib/presentation/layouts/widgets/sidebar/sidebar.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'sidebar_header.dart';
import 'sidebar_menu.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: const Column(
        children: [
          SidebarHeader(),
          Expanded(child: SidebarMenu()),
        ],
      ),
    );
  }
}