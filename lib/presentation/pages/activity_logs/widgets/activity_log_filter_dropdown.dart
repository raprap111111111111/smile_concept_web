import 'package:flutter/material.dart';

import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ActivityLogFilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool fullWidth;

  const ActivityLogFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      style: AppTextStyles.bodySmall,
      items: items,
      onChanged: onChanged,
    );

    return fullWidth ? field : SizedBox(width: 180, child: field);
  }
}