// lib/presentation/pages/doctors/widgets/doctor_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/doctor_repository.dart';
import '../../../providers/user/dentist_users_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class DoctorFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? doctor;

  const DoctorFormDialog({super.key, this.doctor});

  @override
  ConsumerState<DoctorFormDialog> createState() => _DoctorFormDialogState();
}

class _DoctorFormDialogState extends ConsumerState<DoctorFormDialog> {
  late final TextEditingController _specCtrl;
  late final TextEditingController _licenseCtrl;
  int? _selectedUserId;
  bool _isSaving = false;

  bool get isEdit => widget.doctor != null;

  @override
  void initState() {
    super.initState();
    _specCtrl = TextEditingController(
      text: widget.doctor?['specialization']?.toString() ?? '',
    );
    _licenseCtrl = TextEditingController(
      text: widget.doctor?['license_number']?.toString() ?? '',
    );
    _selectedUserId =
        widget.doctor?['user_id'] is int ? widget.doctor!['user_id'] : null;
  }

  @override
  void dispose() {
    _specCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  // ── Save handler ──────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(doctorRepositoryProvider);
      final data = <String, dynamic>{
        if (!isEdit) 'user_id': _selectedUserId,
        'specialization': _specCtrl.text.trim(),
        'license_number': _licenseCtrl.text.trim(),
      };

      if (isEdit) {
        await repo.updateDoctor(widget.doctor!['id'] as int, data);
      } else {
        await repo.createDoctor(data);
      }

      ref.invalidate(doctorsProvider);

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackbar(
        isEdit ? 'Doctor updated' : 'Doctor created',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validate() {
    if (!isEdit && _selectedUserId == null) {
      _showSnackbar('Please select a user', isError: true);
      return false;
    }
    if (_specCtrl.text.trim().isEmpty) {
      _showSnackbar('Specialization is required', isError: true);
      return false;
    }
    if (_licenseCtrl.text.trim().isEmpty) {
      _showSnackbar('License number is required', isError: true);
      return false;
    }
    return true;
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.success,
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildBody(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
          topRight: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEdit ? Icons.edit : Icons.add_moderator_outlined,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'Edit Doctor' : 'Create New Doctor',
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEdit) ...[
            _FieldLabel('Select User (must have dentist role)'),
            const SizedBox(height: 8),
            _UserDropdown(
              value: _selectedUserId,
              onChanged: (v) => setState(() => _selectedUserId = v),
            ),
            const SizedBox(height: 14),
          ],
          const _FieldLabel('Specialization'),
          const SizedBox(height: 8),
          _TextInput(
            controller: _specCtrl,
            hint: 'e.g. Orthodontist, Endodontist',
          ),
          const SizedBox(height: 14),
          const _FieldLabel('License Number'),
          const SizedBox(height: 8),
          _TextInput(
            controller: _licenseCtrl,
            hint: 'PRC or license reference',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isSaving ? null : _handleSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}

// ── Field Label ────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
    );
  }
}

// ── User Dropdown ──────────────────────────────────────────────
class _UserDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _UserDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch top-level provider — same instance every rebuild
    final usersAsync = ref.watch(dentistUsersProvider);

    return usersAsync.when(
      loading: () => _loadingBox(),
      error: (e, _) => _errorBox(context, ref, e.toString()),
      data: (users) => _dropdown(users),
    );
  }

  // ── States ────────────────────────────────────────────
  Widget _loadingBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: _boxDecoration(),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Loading users...'),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, WidgetRef ref, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: _boxDecoration(borderColor: AppColors.error),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load users',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(dentistUsersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: _boxDecoration(),
        child: Text(
          'No available dentist users. Create a user with dentist role first.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _boxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: AppColors.background,
          value: value,
          hint: Text(
            'Select a user',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          items: users.map((u) {
            return DropdownMenuItem<int>(
              value: u['id'] as int,
              child: Text(
                '${u['name']}  ·  ${u['email']}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      border: Border.all(color: borderColor ?? AppColors.border),
    );
  }
}

// ── Text Input ─────────────────────────────────────────────────
class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
      decoration: InputDecoration(hintText: hint),
    );
  }
}