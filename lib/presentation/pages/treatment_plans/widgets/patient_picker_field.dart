// lib/presentation/pages/treatment_plans/widgets/patient_picker_field.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/patient/patient_model.dart';
import '../../../providers/patient/patient_search_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../widgets/shared/picker_dialog_chrome.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

/// A tappable field that opens a searchable patient picker dialog.
/// Server-side search — safe for thousands of patients.
///
/// Colours are pinned to [AppColors] instead of the ambient scheme: main.dart
/// still boots `ThemeData.dark()`, so theme-driven text here would render
/// near-white on the form's white card.
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
    final picked = selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient *',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            onTap: () => _open(context),
            hoverColor: AppColors.accentWithOpacity(0.12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: picked == null ? AppColors.surface : AppColors.background,
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : picked == null
                          ? AppColors.line
                          : AppColors.primaryLight,
                  width: hasError ? 1.5 : 1,
                ),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Row(
                children: [
                  PatientAvatar(name: picked?.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: picked == null
                        ? const Text(
                            'Tap to search patients by name, email or phone',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                picked.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (picked.phone != null &&
                                      picked.phone!.isNotEmpty)
                                    picked.phone!,
                                  if (picked.email.isNotEmpty) picked.email,
                                ].join('  ·  '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    picked == null
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
                  'Please select a patient',
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
}

/// Circular initial badge, shared by the field and the result rows.
class PatientAvatar extends StatelessWidget {
  final String? name;
  final double size;

  const PatientAvatar({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentWithOpacity(0.5)),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
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
    final resultsAsync = ref.watch(patientSearchProvider(_query));

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
            const PickerDialogHeader(
              icon: Icons.person_search_rounded,
              title: 'Select Patient',
              subtitle: 'Search by name, email, or phone',
            ),
            PickerSearchField(
              controller: _ctrl,
              hintText: 'Type to search patients…',
              onChanged: _onChanged,
              onClear: () {
                _ctrl.clear();
                _onChanged('');
              },
            ),
            const Divider(height: 1, color: AppColors.line),

            // ── Results ───────────────────────────
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryDark),
                    ),
                  ),
                ),
                error: (e, _) => PickerDialogEmpty(
                  icon: Icons.wifi_off_rounded,
                  title: 'Could not load patients',
                  message: describeError(e),
                  action: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(patientSearchProvider(_query)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadius,
                        ),
                      ),
                    ),
                  ),
                ),
                data: (patients) {
                  if (patients.isEmpty) {
                    return PickerDialogEmpty(
                      icon: Icons.person_off_outlined,
                      title: _query.isEmpty
                          ? 'No patients yet'
                          : 'No matches',
                      message: _query.isEmpty
                          ? 'Add patients from the Patients page first.'
                          : 'No patient matches "$_query". '
                              'Try a different name, email, or phone.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: patients.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 20,
                      color: AppColors.line,
                    ),
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
                horizontal: 20,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _query.isEmpty
                          ? 'Showing recent patients. Type to search.'
                          : 'Showing results for "$_query"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}

// ── Single patient row ──────────────────────────────────────
class _PatientTile extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientTile({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accentWithOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              PatientAvatar(name: patient.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (patient.phone != null &&
                            patient.phone!.isNotEmpty) ...[
                          const Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            patient.phone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (patient.email.isNotEmpty) ...[
                          const Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              patient.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
