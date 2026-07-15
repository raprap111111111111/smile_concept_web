// lib/presentation/pages/treatment_plans/widgets/treatment_plan_status_filter.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

class TreatmentPlanStatusFilter extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const TreatmentPlanStatusFilter({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: 14,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((status) {
            final isActive = selected == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatusChip(
                label: status,
                active: isActive,
                onTap: () => onChanged(status),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusChip extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? AppColors.primary
        : _hovered
            ? AppColors.accentWithOpacity(0.18)
            : AppColors.surface;

    final borderColor = widget.active
        ? AppColors.primary
        : AppColors.line;

    final textColor = widget.active ? Colors.white : AppColors.ink;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            _capitalize(widget.label),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}