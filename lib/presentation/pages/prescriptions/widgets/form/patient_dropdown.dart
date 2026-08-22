// lib/presentation/pages/prescriptions/widgets/form/patient_dropdown.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/patient/patient_list_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '/presentation/widgets/shared/status_field.dart';

/// Searchable patient picker (same contract as before).
/// - selectedPatientId = patient's userId
/// - onChanged(userId)
class PatientDropdown extends ConsumerStatefulWidget {
  final int? selectedPatientId;
  final ValueChanged<int?> onChanged;

  const PatientDropdown({
    super.key,
    required this.selectedPatientId,
    required this.onChanged,
  });

  @override
  ConsumerState<PatientDropdown> createState() => _PatientDropdownState();
}

class _PatientDropdownState extends ConsumerState<PatientDropdown> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  String _localQuery = '';
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    // Ensure list is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(patientListProvider);
      if (state.patients.isEmpty && !state.isLoading) {
        ref.read(patientListProvider.notifier).refresh();
      }
      _syncSelectedLabel();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.selectedPatientId == null) {
        setState(() => _showResults = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PatientDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPatientId != widget.selectedPatientId) {
      _syncSelectedLabel();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncSelectedLabel() {
    final patients = ref.read(patientListProvider).patients;
    final id = widget.selectedPatientId;
    if (id == null) {
      if (_searchCtrl.text.isNotEmpty && !_focusNode.hasFocus) {
        _searchCtrl.clear();
      }
      return;
    }
    final match = patients.where((p) => p.userId == id).toList();
    if (match.isNotEmpty) {
      _searchCtrl.text = match.first.name;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _localQuery = value.trim().toLowerCase();
        _showResults = true;
      });

      // If your patientListProvider supports server search, call it here.
      // Example (uncomment if available):
      // ref.read(patientListProvider.notifier).search(value);
    });
  }

  void _select(int userId, String name) {
    setState(() {
      _searchCtrl.text = name;
      _showResults = false;
      _localQuery = '';
    });
    _focusNode.unfocus();
    widget.onChanged(userId);
  }

  void _clear() {
    setState(() {
      _searchCtrl.clear();
      _localQuery = '';
      _showResults = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientListProvider);

    if (patientsState.isLoading && patientsState.patients.isEmpty) {
      return const StatusField(label: 'Loading patients...');
    }

    if (patientsState.errorMessage != null && patientsState.patients.isEmpty) {
      return StatusField(
        label: 'Failed to load patients',
        isError: true,
        onRetry: () => ref.read(patientListProvider.notifier).refresh(),
      );
    }

    if (patientsState.patients.isEmpty) {
      return const StatusField(label: 'No patients available');
    }

    // Keep label in sync when list finishes loading
    final selectedId = widget.selectedPatientId;
    final selected = selectedId == null
        ? null
        : patientsState.patients
            .where((p) => p.userId == selectedId)
            .cast<dynamic>()
            .toList();

    if (selected != null &&
        selected.isNotEmpty &&
        _searchCtrl.text != selected.first.name &&
        !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchCtrl.text = selected.first.name;
      });
    }

    final q = _localQuery;
    final filtered = q.isEmpty
        ? patientsState.patients
        : patientsState.patients.where((p) {
            final name = p.name.toLowerCase();
            final email = p.email.toLowerCase();
            final phone = (p.phone ?? '').toLowerCase();
            return name.contains(q) || email.contains(q) || phone.contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search field (Appointments style) ───────────────────────────
        TextFormField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          readOnly: selectedId != null,
          onChanged: _onSearchChanged,
          onTap: () {
            if (selectedId == null) {
              setState(() => _showResults = true);
            }
          },
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          validator: (_) =>
              selectedId == null ? 'Please select a patient' : null,
          decoration: InputDecoration(
            labelText: 'Patient *',
            hintText: 'Search patient by name or phone…',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textTertiary),
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(
              selectedId != null ? Icons.face : Icons.search_rounded,
              color: selectedId != null
                  ? AppColors.primary
                  : AppColors.textTertiary,
              size: 20,
            ),
            suffixIcon: selectedId != null
                ? IconButton(
                    tooltip: 'Change patient',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: _clear,
                  )
                : (_searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: selectedId != null
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        // ── Results panel (LIGHT — no black menu) ───────────────────────
        if (_showResults && selectedId == null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      q.isEmpty
                          ? 'Type a name or phone to search…'
                          : 'No patients found for "$q".',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final subtitle = [
                        if (p.email.isNotEmpty) p.email,
                        if ((p.phone ?? '').isNotEmpty) p.phone!,
                      ].join(' • ');

                      return Material(
                        color: AppColors.surface,
                        child: ListTile(
                          dense: true,
                          hoverColor: AppColors.accentLight,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.accentLight,
                            child: Text(
                              p.name.isNotEmpty
                                  ? p.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: subtitle.isEmpty
                              ? null
                              : Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                          onTap: () => _select(p.userId, p.name),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}