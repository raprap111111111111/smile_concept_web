// lib/presentation/widgets/shared/action_icon_button.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// A compact, tinted icon button for row/card actions.
///
/// Matches the visual language of table action buttons (view/edit/delete).
class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.tooltip,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;
  final double size;

  /// View action — info blue.
  factory ActionIconButton.view({
    Key? key,
    required VoidCallback onPressed,
    String tooltip = 'View',
  }) =>
      ActionIconButton(
        key: key,
        icon: Icons.visibility_outlined,
        onPressed: onPressed,
        color: AppColors.info,
        tooltip: tooltip,
      );

  /// Edit action — warning amber.
  factory ActionIconButton.edit({
    Key? key,
    required VoidCallback onPressed,
    String tooltip = 'Edit',
  }) =>
      ActionIconButton(
        key: key,
        icon: Icons.edit_outlined,
        onPressed: onPressed,
        color: AppColors.warning,
        tooltip: tooltip,
      );

  /// Delete action — error red.
  factory ActionIconButton.delete({
    Key? key,
    required VoidCallback onPressed,
    String tooltip = 'Delete',
  }) =>
      ActionIconButton(
        key: key,
        icon: Icons.delete_outline_rounded,
        onPressed: onPressed,
        color: AppColors.error,
        tooltip: tooltip,
      );

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconSizeSmall,
          color: color,
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}