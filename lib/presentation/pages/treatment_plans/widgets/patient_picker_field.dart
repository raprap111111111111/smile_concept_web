// lib/presentation/pages/treatment_plans/widgets/patient_picker_field.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/patient/patient_model.dart';
import '../../../providers/patient/patient_search_provider.dart';

/// A tappable field that opens a searchable patient picker dialog.
/// Server-side search — safe for thousands of patients.
class PatientPickerField extends StatelessWidget {
  final PatientModel? selected;
  final bool hasError;
  final ValueChanged<PatientModel> onPicked;

  const PatientPickerField({
    super.key,
    required this.selected,
    required this.onPicked,
    this.hasError = false,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<PatientModel>(
      context: context,
      builder: (_) => const _PatientPickerDialog(),
    );
    if (result != null) onPicked(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.outline.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _avatar(context, selected?.name),
                const SizedBox(width: 12),
                Expanded(
                  child: selected == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select patient',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to search patients',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selected!.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (selected!.phone != null &&
                                selected!.phone!.isNotEmpty)
                              Text(
                                selected!.phone!,
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
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'Please select a patient',
              style: TextStyle(
                  color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _avatar(BuildContext context, String? name) {
    final theme = Theme.of(context);
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Search Dialog ─────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════
class _PatientPickerDialog extends ConsumerStatefulWidget {
  const _PatientPickerDialog();

  @override
  ConsumerState<_PatientPickerDialog> createState() =>
      _PatientPickerDialogState();
}

class _PatientPickerDialogState
    extends ConsumerState<_PatientPickerDialog> {
  final _ctrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultsAsync = ref.watch(patientSearchProvider(_query));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 10, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person_search,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Patient',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(
                          'Search by name, email, or phone',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Search box ────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search patients...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            _onChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 8),
            Divider(
                height: 1,
                color: theme.colorScheme.outline
                    .withValues(alpha: 0.15)),

            // ── Results ───────────────────────────
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(e.toString(),
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => ref.invalidate(
                              patientSearchProvider(_query)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (patients) {
                  if (patients.isEmpty) {
                    return _emptyState(context);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: patients.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 72,
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.1)),
                    itemBuilder: (_, i) {
                      final p = patients[i];
                      return _PatientTile(
                        patient: p,
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Footer hint ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surface.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(
                      color: theme.colorScheme.outline
                          .withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: theme.hintColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _query.isEmpty
                          ? 'Showing recent patients. Type to search.'
                          : 'Showing results for "$_query"',
                      style: TextStyle(
                          fontSize: 12, color: theme.hintColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined,
                size: 48, color: theme.hintColor),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty
                  ? 'No patients yet'
                  : 'No patients match "$_query"',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: theme.hintColor),
            ),
            const SizedBox(height: 4),
            Text(
              _query.isEmpty
                  ? 'Add patients from the Patients page first.'
                  : 'Try a different name, email, or phone.',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single patient row ──────────────────────────────────────
class _PatientTile extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientTile({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = patient.name.trim().isNotEmpty
        ? patient.name.trim()[0].toUpperCase()
        : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(initial,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (patient.phone != null &&
                          patient.phone!.isNotEmpty) ...[
                        Icon(Icons.phone,
                            size: 12, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(patient.phone!,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor)),
                        const SizedBox(width: 10),
                      ],
                      if (patient.email.isNotEmpty) ...[
                        Icon(Icons.email_outlined,
                            size: 12, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            patient.email,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}