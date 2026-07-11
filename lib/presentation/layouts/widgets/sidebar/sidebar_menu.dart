// lib/presentation/layouts/widgets/sidebar/sidebar_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth/permission_provider.dart';
import 'sidebar_menu_item.dart';
import 'sidebar_nav_config.dart';
import 'sidebar_section.dart';

/// Builds the sidebar menu with permission-based filtering.
class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(permissionServiceProvider);
    final sections = SidebarNavConfig.buildFor(perm);

    // ── Filter: only visible sections with visible items ─────────────────
    final visibleSections = sections
        .map((section) {
          final items = section.items
              .where((item) => perm.canAny(item.permissions))
              .toList();
          return _VisibleSection(section: section, items: items);
        })
        .where((s) => s.items.isNotEmpty)
        .toList();

    // ── Build UI with dividers ────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildChildren(visibleSections),
      ),
    );
  }

  List<Widget> _buildChildren(List<_VisibleSection> sections) {
    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i];
      children.add(
        SidebarSection(
          title: s.section.title,
          children: s.items
              .map((item) => SidebarMenuItem(
                    icon: item.icon,
                    title: item.title,
                    routeName: item.routeName,
                  ))
              .toList(),
        ),
      );
      if (i < sections.length - 1) children.add(_gap());
    }
    return children;
  }

  Widget _gap() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
      );
}

/// Internal helper for filtered results
class _VisibleSection {
  final NavSection section;
  final List<NavItem> items;
  const _VisibleSection({required this.section, required this.items});
}