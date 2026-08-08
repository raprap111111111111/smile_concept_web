// lib/presentation/layouts/widgets/sidebar/sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout/sidebar_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'sidebar_header.dart';
import 'sidebar_menu.dart';

/// Shared by the panel width and the topbar toggle icon so both land together.
const kSidebarAnimationDuration = Duration(milliseconds: 220);

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final width = collapsed
        ? AppDimensions.sidebarCollapsedWidth
        : AppDimensions.sidebarWidth;

    return AnimatedContainer(
      duration: kSidebarAnimationDuration,
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.background, // pure white
        border: Border(
          right: BorderSide(color: AppColors.line),
        ),
      ),
      // The contents are laid out at the *target* width for the whole
      // animation and clipped to whatever the panel currently measures.
      // Without the OverflowBox they would be re-laid out at every
      // intermediate width and overflow on the way in.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: width,
          maxWidth: width,
          child: Column(
            children: [
              SidebarHeader(collapsed: collapsed),
              Expanded(child: SidebarMenu(collapsed: collapsed)),
            ],
          ),
        ),
      ),
    );
  }
}
