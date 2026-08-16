// lib/presentation/widgets/shared/item_picker_dialog.dart

import 'package:flutter/material.dart';

import '../../../data/models/inventory/inventory_item_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'picker_dialog_chrome.dart';

/// Searchable list rather than a dropdown.
///
/// The items endpoint is fetched with a page cap, and a clinic's catalog runs
/// long — a bare dropdown makes anything past the fold unreachable.
///
/// Pops the picked [InventoryItemModel], or null when cancelled. Callers pass
/// only the items still available, so filtering out what is already on the
/// form is their job, not the dialog's.
class ItemPickerDialog extends StatefulWidget {
  final List<InventoryItemModel> items;
  final String title;

  const ItemPickerDialog({
    super.key,
    required this.items,
    this.title = 'Add consumable',
  });

  @override
  State<ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends State<ItemPickerDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<InventoryItemModel> get _matches {
    if (_query.isEmpty) return widget.items;

    final needle = _query.toLowerCase();

    return widget.items.where((item) {
      return item.name.toLowerCase().contains(needle) ||
          (item.sku ?? '').toLowerCase().contains(needle) ||
          (item.category ?? '').toLowerCase().contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final count = widget.items.length;

    // showDialog pushes onto the root navigator, so a light theme pinned by the
    // dialog that opened this one does not reach here — without this the whole
    // picker inherits main.dart's ThemeData.dark() and renders white-on-black.
    return Theme(
      data: AppTheme.lightTheme,
      child: Dialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PickerDialogHeader(
                icon: Icons.inventory_2_outlined,
                title: widget.title,
                subtitle: '$count item${count == 1 ? '' : 's'} available',
              ),
              PickerSearchField(
                controller: _controller,
                hintText: 'Search by name, SKU or category…',
                onChanged: (value) => setState(() => _query = value.trim()),
                onClear: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
              ),
              const Divider(height: 1, color: AppColors.line),
              Flexible(
                child: widget.items.isEmpty
                    ? const PickerDialogEmpty(
                        icon: Icons.inventory_2_outlined,
                        title: 'Nothing left to add',
                        message:
                            'Every item in the catalog is already on this list.',
                      )
                    : matches.isEmpty
                        ? PickerDialogEmpty(
                            icon: Icons.search_off_rounded,
                            title: 'No matches',
                            message: 'No item matches "$_query".',
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: matches.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: AppColors.line,
                            ),
                            itemBuilder: (_, index) => _ItemTile(
                              item: matches[index],
                              onTap: () =>
                                  Navigator.of(context).pop(matches[index]),
                            ),
                          ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One catalog row: what it is on the left, how it is counted on the right.
class _ItemTile extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = [item.sku, item.categoryLabel]
        .where((value) => value != null && value.isNotEmpty)
        .join('  ·  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Colour rather than scale — a growing row would shove its neighbours.
        hoverColor: AppColors.accentWithOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if ((item.unitOfMeasure ?? '').isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    item.unitOfMeasure!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
