// lib/presentation/pages/inventory/widgets/item_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/inventory/inventory_form_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'dropdown_states.dart';

class ItemDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const ItemDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsSimpleListProvider);

    return itemsAsync.when(
      loading: () =>
          const DropdownSkeleton(label: 'Loading items...'),
      error: (e, _) => DropdownError(
        message: 'Failed to load items',
        onRetry: () => ref.invalidate(itemsSimpleListProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const DropdownError(
            message: 'No items available. Please add items to the catalog first.',
          );
        }

        return DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          style: AppTextStyles.bodyMedium,
          decoration: const InputDecoration(
            labelText: 'Item *',
            prefixIcon: Icon(Icons.medical_services_outlined),
            helperText: 'Which item to stock',
          ),
          hint: Text(
            'Select an item',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (item.sku != null || item.category != null)
                        Text(
                          [
                            if (item.sku != null) 'SKU: ${item.sku}',
                            if (item.category != null) item.category,
                          ].join(' • '),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select an item' : null,
        );
      },
    );
  }
}