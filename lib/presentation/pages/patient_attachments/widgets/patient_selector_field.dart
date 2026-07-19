// lib/presentation/pages/patient_attachments/widgets/patient_selector_field.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/models/patient_attachment/patient_summary_model.dart';
import '/presentation/providers/patient_attachment/patients_provider.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

/// Reusable searchable patient selector.
///
/// Uses [allPatientsProvider] to fetch all users.
/// Displays a bottom sheet with search when tapped.
///
/// Usage:
/// ```dart
/// PatientSelectorField(
///   selectedUserId: _selectedUserId,
///   onChanged: (id) => setState(() => _selectedUserId = id),
/// )
/// ```
class PatientSelectorField extends ConsumerWidget {
  final int? selectedUserId;
  final ValueChanged<int?> onChanged;
  final String label;
  final String hint;
  final bool required;
  final bool readOnly;

  const PatientSelectorField({
    super.key,
    required this.selectedUserId,
    required this.onChanged,
    this.label = 'Patient',
    this.hint = 'Select patient',
    this.required = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(label, style: AppTextStyles.labelLarge),
            if (required)
              Text(' *',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),

        // Selector box
        InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          onTap: readOnly ? null : () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: readOnly ? AppColors.surface : AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  selectedUserId != null ? Icons.person : Icons.person_outline,
                  color: selectedUserId != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildSelectedDisplay(ref)),
                if (!readOnly)
                  const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                if (readOnly)
                  const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDisplay(WidgetRef ref) {
    if (selectedUserId == null) {
      return Text(
        hint,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      );
    }

    final patientsAsync = ref.watch(allPatientsProvider);

    return patientsAsync.when(
      data: (patients) {
        final patient = patients.firstWhere(
          (p) => p.id == selectedUserId,
          orElse: () => PatientSummary(
            id: selectedUserId!,
            name: 'Patient #$selectedUserId',
            email: '',
          ),
        );

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patient.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (patient.email.isNotEmpty)
                    Text(
                      patient.email,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            // Clear button
            if (!readOnly)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child:
                      Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                ),
              ),
          ],
        );
      },
      loading: () => Text(
        'Loading...',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      ),
      error: (_, __) => Text(
        'Patient #$selectedUserId',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientPickerSheet(selectedId: selectedUserId),
    );

    if (result != null) onChanged(result);
  }
}

// ═══════════════════════════════════════════════════════════
// PATIENT PICKER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════
class _PatientPickerSheet extends ConsumerStatefulWidget {
  final int? selectedId;

  const _PatientPickerSheet({this.selectedId});

  @override
  ConsumerState<_PatientPickerSheet> createState() =>
      _PatientPickerSheetState();
}

class _PatientPickerSheetState extends ConsumerState<_PatientPickerSheet> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(allPatientsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Select Patient', style: AppTextStyles.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ── Patient count ──
            patientsAsync.when(
              data: (patients) {
                final filtered = _filterPatients(patients);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} patient${filtered.length == 1 ? '' : 's'}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(), 
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),

            // ── List ──
            Expanded(
              child: patientsAsync.when(
                data: (patients) {
                  final filtered = _filterPatients(patients);

                  if (filtered.isEmpty) return const _EmptyState();

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
                      final isSelected = patient.id == widget.selectedId;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius),
                          ),
                          tileColor: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : null,
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.15),
                            foregroundColor:
                                isSelected ? Colors.white : AppColors.primary,
                            child: Text(
                              patient.initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            patient.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.ink,
                            ),
                          ),
                          subtitle: patient.email.isNotEmpty
                              ? Text(patient.email,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ))
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary)
                              : patient.attachmentCount > 0
                                  ? Text(
                                      '${patient.attachmentCount} files',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    )
                                  : null,
                          onTap: () => Navigator.pop(context, patient.id),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(allPatientsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PatientSummary> _filterPatients(List<PatientSummary> patients) {
    if (_search.isEmpty) return patients;
    return patients
        .where((p) =>
            p.name.toLowerCase().contains(_search) ||
            p.email.toLowerCase().contains(_search))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No patients found', style: AppTextStyles.titleSmall),
          const SizedBox(height: 4),
          Text('Try a different search',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ERROR STATE
// ═══════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load patients', style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(error,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
