import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class YesNoQuestion extends StatelessWidget {
  final String question;
  final bool? value;
  final ValueChanged<bool> onChanged;

  const YesNoQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(question, style: AppTextStyles.bodySmall),
          ),
          _YesNoButton(
            label: 'Yes',
            selected: value == true,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 8),
          _YesNoButton(
            label: 'No',
            selected: value == false,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YesNoButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color:
                  selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}