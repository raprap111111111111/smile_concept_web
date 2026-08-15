// lib/presentation/pages/treatment_plans/widgets/treatment_picker_field.dart

import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../data/models/treatment/treatment_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'picker_dialog_chrome.dart';

/// Tappable field that opens the catalog picker for one plan step.
///
/// Colours are pinned to [AppColors]; the page hosts a light `Theme`, but the
/// dialog is rendered by the root navigator, so nothing here leans on the
/// ambient scheme.
class TreatmentPickerField extends StatelessWidget {
  final TreatmentPlanItemForm item;
  final List<TreatmentModel> treatments;
  final bool isLoading;
  final VoidCallback onChanged;

  const TreatmentPickerField({
    super.key,
    required this.item,
    required this.treatments,
    required this.isLoading,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final result = await showDialog<TreatmentModel>(
      context: context,
      builder: (_) => _TreatmentPickerDialog(
        treatments: treatments,
        selectedId: item.selectedTreatment?.id,
      ),
    );
    if (result != null) {
      item.selectedTreatment = result;
      item.treatmentError = false;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = item.selectedTreatment;
    final hasError = item.treatmentError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TREATMENT *',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            onTap: isLoading ? null : () => _pick(context),
            hoverColor: AppColors.accentWithOpacity(0.12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected == null
                    ? AppColors.surface
                    : AppColors.background,
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : selected == null
                          ? AppColors.line
                          : AppColors.primaryLight,
                  width: hasError ? 1.5 : 1,
                ),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: selected == null
                        ? AppColors.textTertiary
                        : AppColors.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _content(selected)),
                  const SizedBox(width: 8),
                  Icon(
                    selected == null
                        ? Icons.search_rounded
                        : Icons.swap_horiz_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 2),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: AppColors.error),
                SizedBox(width: 6),
                Text(
                  'Pick a treatment for this step',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _content(TreatmentModel? selected) {
    if (isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryDark),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading catalog…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (selected == null) {
      return const Text(
        'Browse the treatment catalog',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selected.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.ink,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${formatMoney(selected.price)}  ·  ${selected.durationLabel}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Search Dialog ─────────────────────────────────────────────
class _TreatmentPickerDialog extends StatefulWidget {
  final List<TreatmentModel> treatments;
  final int? selectedId;

  const _TreatmentPickerDialog({
    required this.treatments,
    this.selectedId,
  });

  @override
  State<_TreatmentPickerDialog> createState() =>
      _TreatmentPickerDialogState();
}

class _TreatmentPickerDialogState extends State<_TreatmentPickerDialog> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<TreatmentModel> get _filtered {
    if (_q.isEmpty) return widget.treatments;
    final q = _q.toLowerCase();
    return widget.treatments
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Dialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PickerDialogHeader(
              icon: Icons.medical_services_outlined,
              title: 'Select Treatment',
              subtitle: '${widget.treatments.length} '
                  'treatment${widget.treatments.length == 1 ? '' : 's'} '
                  'in catalog',
            ),
            PickerSearchField(
              controller: _ctrl,
              hintText: 'Search by name or description…',
              onChanged: (v) => setState(() => _q = v.trim()),
              onClear: () {
                _ctrl.clear();
                setState(() => _q = '');
              },
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: widget.treatments.isEmpty
                  ? const PickerDialogEmpty(
                      icon: Icons.inventory_2_outlined,
                      title: 'Catalog is empty',
                      message:
                          'Add treatments under Treatments / Services first.',
                    )
                  : filtered.isEmpty
                      ? PickerDialogEmpty(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message: 'Nothing in the catalog matches "$_q".',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 20,
                            endIndent: 20,
                            color: AppColors.line,
                          ),
                          itemBuilder: (_, i) {
                            final t = filtered[i];
                            return _TreatmentTile(
                              treatment: t,
                              isSelected: t.id == widget.selectedId,
                              onTap: () => Navigator.pop(context, t),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentTile extends StatelessWidget {
  final TreatmentModel treatment;
  final bool isSelected;
  final VoidCallback onTap;

  const _TreatmentTile({
    required this.treatment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.accentWithOpacity(0.14)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accentWithOpacity(0.12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            treatment.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          treatment.durationLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (treatment.description != null &&
                            treatment.description!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              treatment.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentWithOpacity(0.18),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: Text(
                  formatMoney(treatment.price),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
