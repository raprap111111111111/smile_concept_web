// lib/presentation/pages/treatment_plans/widgets/plan_item_card.dart

import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../data/models/treatment/treatment_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'treatment_picker_field.dart';

/// One treatment step inside the plan builder.
///
/// Every colour is pinned to [AppColors] rather than resolved from
/// `Theme.of(context)` — main.dart still boots `ThemeData.dark()`, so a
/// theme-driven card renders as a dark block inside the white section panel.
class PlanItemCard extends StatefulWidget {
  final int index;
  final TreatmentPlanItemForm item;
  final List<TreatmentModel> availableTreatments;
  final bool isLoading;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const PlanItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.availableTreatments,
    required this.isLoading,
    required this.onChanged,
    this.onMoveUp,
    this.onMoveDown,
    this.onRemove,
  });

  @override
  State<PlanItemCard> createState() => _PlanItemCardState();
}

class _PlanItemCardState extends State<PlanItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = item.selectedTreatment;
    final hasSelection = selected != null;
    final hasError = item.treatmentError;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(
            color: hasError
                ? AppColors.error
                : _hovered
                    ? AppColors.primaryLight
                    : AppColors.line,
            width: hasError ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            _header(hasSelection, selected),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TreatmentPickerField(
                    item: item,
                    treatments: widget.availableTreatments,
                    isLoading: widget.isLoading,
                    onChanged: widget.onChanged,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 420;
                      final price = _labeled(
                        'Unit Price',
                        _priceBox(item),
                        hint: 'From catalog',
                      );
                      final qty = _labeled(
                        'Quantity',
                        _qtyStepper(item),
                      );
                      final subtotal = _labeled(
                        'Subtotal',
                        _subtotalBox(item),
                      );

                      if (stack) {
                        return Column(
                          children: [
                            price,
                            const SizedBox(
                                height: AppDimensions.paddingSmall),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: qty),
                                const SizedBox(width: 12),
                                Expanded(child: subtotal),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: price),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: qty),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: subtotal),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _labeled('Step Notes', _notesField(item), optional: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _header(bool hasSelection, TreatmentModel? selected) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge - 1),
        ),
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasSelection ? AppColors.primary : AppColors.textTertiary,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasSelection ? selected!.name : 'No treatment selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color:
                        hasSelection ? AppColors.ink : AppColors.textSecondary,
                    fontStyle:
                        hasSelection ? FontStyle.normal : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasSelection) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${formatMoney(item.subtotal)}  ·  Qty ${item.quantity}'
                    '  ·  ${selected!.durationLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          _iconBtn(Icons.keyboard_arrow_up_rounded, widget.onMoveUp,
              'Move step up'),
          _iconBtn(Icons.keyboard_arrow_down_rounded, widget.onMoveDown,
              'Move step down'),
          _iconBtn(Icons.delete_outline_rounded, widget.onRemove,
              'Remove this step',
              danger: true),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    VoidCallback? onTap,
    String tip, {
    bool danger = false,
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        // 44x44 keeps the control above the minimum touch-target size.
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        splashRadius: 22,
        color: danger ? AppColors.error : AppColors.textSecondary,
        disabledColor: AppColors.textTertiary.withValues(alpha: 0.45),
        style: IconButton.styleFrom(
          hoverColor: enabled
              ? (danger
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.accentWithOpacity(0.2))
              : Colors.transparent,
        ),
      ),
    );
  }

  // ── Fields ─────────────────────────────────────────────────
  Widget _labeled(
    String label,
    Widget child, {
    String? hint,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text(
                'optional',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (hint != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: hint,
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _priceBox(TreatmentPlanItemForm item) {
    return Container(
      width: double.infinity,
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        formatMoney(item.price),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: item.selectedTreatment == null
              ? AppColors.textTertiary
              : AppColors.ink,
        ),
      ),
    );
  }

  Widget _subtotalBox(TreatmentPlanItemForm item) {
    return Container(
      width: double.infinity,
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.16),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.accentWithOpacity(0.4)),
      ),
      child: Text(
        formatMoney(item.subtotal),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _qtyStepper(TreatmentPlanItemForm item) {
    final canDec = item.quantity > 1;
    final canInc = item.quantity < 99;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _stepBtn(
            icon: Icons.remove_rounded,
            tip: 'Decrease quantity',
            enabled: canDec,
            onTap: () {
              item.quantity--;
              widget.onChanged();
            },
            radius: const BorderRadius.horizontal(
              left: Radius.circular(AppDimensions.borderRadius),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          _stepBtn(
            icon: Icons.add_rounded,
            tip: 'Increase quantity',
            enabled: canInc,
            onTap: () {
              item.quantity++;
              widget.onChanged();
            },
            radius: const BorderRadius.horizontal(
              right: Radius.circular(AppDimensions.borderRadius),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required String tip,
    required bool enabled,
    required VoidCallback onTap,
    required BorderRadius radius,
  }) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: radius,
          hoverColor: AppColors.accentWithOpacity(0.2),
          child: SizedBox(
            width: 44,
            height: 46,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? AppColors.primaryDark
                  : AppColors.textTertiary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notesField(TreatmentPlanItemForm item) {
    return TextFormField(
      controller: item.notesController,
      maxLines: 2,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'e.g. upper left molar, schedule after healing…',
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}
