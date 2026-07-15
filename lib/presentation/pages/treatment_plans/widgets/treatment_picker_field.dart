// lib/presentation/pages/treatment_plans/widgets/treatment_picker_field.dart

import 'package:flutter/material.dart';

import '../../../../data/models/treatment/treatment_model.dart';
import '../../../../data/models/treatment/treatment_plan_model.dart';

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
      builder: (_) => _TreatmentPickerDialog(treatments: treatments),
    );
    if (result != null) {
      item.selectedTreatment = result;
      item.treatmentError = false;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = item.selectedTreatment;
    final borderColor = item.treatmentError
        ? theme.colorScheme.error
        : theme.colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isLoading ? null : () => _pick(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services_outlined,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isLoading
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Loading treatments...'),
                            ],
                          )
                        : selected == null
                            ? Text(
                                'Tap to select treatment from catalog',
                                style: TextStyle(color: theme.hintColor),
                              )
                            : Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selected.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '₱ ${selected.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.hintColor),
                                  ),
                                ],
                              ),
                  ),
                  Icon(
                    selected == null ? Icons.search : Icons.swap_horiz,
                    color: theme.hintColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (item.treatmentError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Please select a treatment',
              style: TextStyle(
                  color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

// ─── Search Dialog ─────────────────────────────────────────────
class _TreatmentPickerDialog extends StatefulWidget {
  final List<TreatmentModel> treatments;
  const _TreatmentPickerDialog({required this.treatments});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _q.isEmpty
        ? widget.treatments
        : widget.treatments
            .where((t) => t.name.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined),
                  const SizedBox(width: 8),
                  const Text('Select Treatment',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search treatments...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: widget.treatments.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child:
                            Text('No treatments available in catalog.'),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No treatments match "$_q"'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final t = filtered[i];
                            return InkWell(
                              onTap: () => Navigator.pop(context, t),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₱${t.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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