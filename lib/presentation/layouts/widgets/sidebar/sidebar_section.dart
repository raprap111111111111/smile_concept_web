// lib/presentation/layouts/widgets/sidebar/sidebar_section.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SidebarSection extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;

  const SidebarSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false, // expanded by default for light theme
  });

  @override
  State<SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<SidebarSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _isExpanded ? 0.0 : -0.25,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Column(children: widget.children)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}