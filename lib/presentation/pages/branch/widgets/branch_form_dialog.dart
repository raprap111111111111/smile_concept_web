import 'package:flutter/material.dart';

import '../../../../data/models/branch/branch_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class BranchFormDialog extends StatefulWidget {
  final BranchModel? branch;

  const BranchFormDialog({
    super.key,
    this.branch,
  });

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _hoursCtrl;

  late bool _isActive;

  bool get _isEdit => widget.branch != null;

  @override
  void initState() {
    super.initState();

    final branch = widget.branch;

    _nameCtrl = TextEditingController(text: branch?.name ?? '');
    _codeCtrl = TextEditingController(text: branch?.branchCode ?? '');
    _addressCtrl = TextEditingController(text: branch?.address ?? '');
    _cityCtrl = TextEditingController(text: branch?.city ?? '');
    _provinceCtrl = TextEditingController(text: branch?.province ?? '');
    _phoneCtrl = TextEditingController(text: branch?.phone ?? '');
    _emailCtrl = TextEditingController(text: branch?.email ?? '');
    _hoursCtrl = TextEditingController(text: branch?.openingHours ?? '');

    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _hoursCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
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
                      _field(
                        _nameCtrl,
                        'Branch Name',
                        hint: 'e.g. Main Branch',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Branch name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _field(
                        _codeCtrl,
                        'Branch Code',
                        hint: 'e.g. BR-001',
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _field(
                        _addressCtrl,
                        'Address',
                        hint: 'Street address',
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _cityCtrl,
                              'City',
                              hint: 'e.g. Manila',
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Expanded(
                            child: _field(
                              _provinceCtrl,
                              'Province',
                              hint: 'e.g. Metro Manila',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _field(
                        _phoneCtrl,
                        'Phone',
                        hint: 'e.g. +63 912 345 6789',
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _field(
                        _emailCtrl,
                        'Email',
                        hint: 'e.g. branch@clinic.com',
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _field(
                        _hoursCtrl,
                        'Opening Hours',
                        hint: 'e.g. 9AM – 6PM',
                      ),
                      const SizedBox(height: AppDimensions.paddingXS),
                      _buildActiveToggle(),
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
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
          topRight: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEdit ? Icons.edit_outlined : Icons.add_business_outlined,
            color: Colors.white,
            size: AppDimensions.iconSize,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Text(
            _isEdit ? 'Edit Branch' : 'Create New Branch',
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: 4,
        ),
        title: Text('Active Branch', style: AppTextStyles.labelLarge),
        subtitle: Text(
          _isActive ? 'Branch is visible and operational' : 'Branch is hidden',
          style: AppTextStyles.labelSmall.copyWith(
            color: _isActive ? AppColors.success : AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        value: _isActive,
        activeColor: AppColors.primary,
        onChanged: (value) => setState(() => _isActive = value),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          ElevatedButton(
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
            onPressed: _submit,
            child: Text(
              _isEdit ? 'Update Branch' : 'Create Branch',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
            children: isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'branch_code': _codeCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'province': _provinceCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'opening_hours': _hoursCtrl.text.trim(),
      'is_active': _isActive,
    };

    Navigator.pop(context, data);
  }
}