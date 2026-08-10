import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/patient/patient_model.dart';
import '../../../providers/patient/patient_search_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Simple patient identity for the dialog.
class PickedPatient {
  final int id;
  final String name;

  const PickedPatient({required this.id, required this.name});
}

class PatientPickerDialog extends ConsumerStatefulWidget {
  const PatientPickerDialog({super.key});

  static Future<PickedPatient?> show(BuildContext context) {
    return showDialog<PickedPatient>(
      context: context,
      builder: (_) => const PatientPickerDialog(),
    );
  }

  @override
  ConsumerState<PatientPickerDialog> createState() =>
      _PatientPickerDialogState();
}

class _PatientPickerDialogState extends ConsumerState<PatientPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _select(PatientModel patient) {
    Navigator.of(context).pop(
      PickedPatient(
        id: patient.id,
        name: patient.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientSearchProvider(_query));

    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.paddingLarge),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            _buildSearchSection(),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(child: _buildResults(patientsAsync)),
            const Divider(height: 1, color: AppColors.divider),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.person_search,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Patient', style: AppTextStyles.titleMedium),
                Text(
                  'Search and tap a patient to continue',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ─── Search box ───────────────────────────────────────────
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Search by patient name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
        ),
        onChanged: (v) {
          setState(() {}); // to toggle the clear button
          _onSearchChanged(v);
        },
      ),
    );
  }

  // ─── Results list ─────────────────────────────────────────
  Widget _buildResults(AsyncValue<List<PatientModel>> patientsAsync) {
    return patientsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Center(
          child: Text(
            'Failed to load patients:\n$e',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (patients) {
        if (patients.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  color: AppColors.textTertiary,
                  size: 40,
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                Text(
                  _query.isEmpty
                      ? 'No patients available'
                      : 'No patients match "$_query"',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSmall,
          ),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: AppColors.divider,
          ),
          itemBuilder: (context, index) {
            final p = patients[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accentLight,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(p.name, style: AppTextStyles.bodyMedium),
              subtitle: Text(
                'ID: ${p.id}',
                style: AppTextStyles.labelSmall,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
              onTap: () => _select(p),
            );
          },
        );
      },
    );
  }

  // ─── Footer ───────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}