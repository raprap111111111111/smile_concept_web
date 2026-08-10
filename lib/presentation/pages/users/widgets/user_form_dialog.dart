// lib/presentation/pages/users/widgets/user_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/role_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? user;

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _passwordConfirmCtrl;

  String? _selectedRole;
  late bool _isActive;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameCtrl =
        TextEditingController(text: user?['name']?.toString() ?? '');
    _emailCtrl =
        TextEditingController(text: user?['email']?.toString() ?? '');
    _phoneCtrl =
        TextEditingController(text: user?['phone']?.toString() ?? '');
    _passwordCtrl = TextEditingController();
    _passwordConfirmCtrl = TextEditingController();

    final roles = user?['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      _selectedRole = first is Map && first['name'] != null
          ? first['name'].toString()
          : first.toString();
    }

    _isActive = _asBool(user?['is_active'] ?? true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormSection(label: 'Personal Information', children: [
                        _FormField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'e.g. Juan Dela Cruz',
                          icon: Icons.person_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        _FormField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          hint: 'e.g. juan@clinic.com',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Email is required'
                              : null,
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        _FormField(
                          controller: _phoneCtrl,
                          label: 'Phone (optional)',
                          hint: 'e.g. 09XX XXX XXXX',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                      ]),
                      if (!_isEdit) ...[
                        const SizedBox(height: AppDimensions.paddingMedium),
                        _FormSection(label: 'Security', children: [
                          _FormField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            hint: 'At least 8 characters',
                            icon: Icons.lock_rounded,
                            obscure: true,
                            validator: (v) =>
                                (v == null || v.length < 8)
                                    ? 'Password must be at least 8 characters'
                                    : null,
                          ),
                          const SizedBox(height: AppDimensions.paddingSmall),
                          _FormField(
                            controller: _passwordConfirmCtrl,
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) => v != _passwordCtrl.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                        ]),
                      ],
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _FormSection(label: 'Access & Role', children: [
                        rolesAsync.when(
                          loading: () => const LinearProgressIndicator(
                            color: AppColors.primary,
                          ),
                          error: (_, __) => Text(
                            'Failed to load roles',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          data: (roles) {
                            final staffRoles = roles.where((r) =>
                                r['name']?.toString() != 'patient').toList();
                            return _RoleDropdown(
                              roles: staffRoles,
                              selectedRole: _selectedRole,
                              onChanged: (v) =>
                                  setState(() => _selectedRole = v),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        _ActiveToggle(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
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
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
          topRight: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
            color: Colors.white,
            size: AppDimensions.iconSize,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit User' : 'Create New User',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isEdit
                      ? 'Update account details and permissions'
                      : 'Add a new staff member to the system',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: AppDimensions.iconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
            child: Text('Cancel', style: AppTextStyles.labelMedium),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
            child: Text(
              _isEdit ? 'Update User' : 'Create User',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'is_active': _isActive,
      if (_selectedRole != null) 'role': _selectedRole,
      if (!_isEdit) ...{
        'password': _passwordCtrl.text,
        'password_confirmation': _passwordConfirmCtrl.text,
      },
    });
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}

// ─── Supporting Form Widgets ──────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.labelLarge),
            const SizedBox(width: AppDimensions.paddingXS),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        ...children,
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: AppDimensions.iconSizeMedium,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.roles,
    required this.selectedRole,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> roles;
  final String? selectedRole;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppColors.background,
          value: selectedRole,
          hint: Text(
            'Select Role',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
          items: roles.map((role) {
            final name = role['name'].toString();
            return DropdownMenuItem<String>(
              value: name,
              child: Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (value ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: AppDimensions.iconSizeSmall,
              color: value ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Status', style: AppTextStyles.labelMedium),
                Text(
                  value ? 'Active — user can log in' : 'Inactive — access revoked',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.success,
            inactiveThumbColor: AppColors.error,
            inactiveTrackColor: AppColors.error.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}