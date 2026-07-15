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
      decoration: const BoxDecoration(
        color: AppColors.background, // pure white
        border: Border(
          right: BorderSide(color: AppColors.line),
        ),
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