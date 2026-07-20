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
    this.initiallyExpanded = false,
  });

  @override
  State<SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<SidebarSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _toggle,
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
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _expandAnimation.value * 3.14159 * 2 * -0.25 +
                          (3.14159 * 2 * -0.25 * (_isExpanded ? 1 : 0)) -
                          (3.14159 * 2 * -0.25 * (_isExpanded ? 1 : 0)) +
                          (_isExpanded
                              ? (1 - _expandAnimation.value) * -1.5708
                              : _expandAnimation.value * -1.5708 + -1.5708) +
                          1.5708,
                      child: child,
                    );
                  },
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
        // Use SizeTransition for smooth, GPU-accelerated expansion
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Column(children: widget.children),
        ),
      ],
    );
  }
}