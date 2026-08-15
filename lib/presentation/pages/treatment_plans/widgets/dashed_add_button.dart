// lib/presentation/pages/treatment_plans/widgets/dashed_add_button.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

class DashedAddButton extends StatefulWidget {
  final VoidCallback onTap;

  const DashedAddButton({super.key, required this.onTap});

  @override
  State<DashedAddButton> createState() => _DashedAddButtonState();
}

class _DashedAddButtonState extends State<DashedAddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: 'Add another treatment step',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingSmall,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.accentWithOpacity(0.18)
                  : AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
              border: Border.all(
                color: _hovered
                    ? AppColors.primary
                    : AppColors.accentWithOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                SizedBox(width: 10),
                // Flexible so the label ellipsises on a phone-width column
                // instead of overflowing the dashed frame.
                Flexible(
                  child: Text(
                    'Add Another Treatment Step',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
