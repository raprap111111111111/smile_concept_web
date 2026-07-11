// lib/presentation/layouts/main_layout.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'widgets/sidebar/sidebar.dart';
import 'widgets/topbar/topbar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const Topbar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}