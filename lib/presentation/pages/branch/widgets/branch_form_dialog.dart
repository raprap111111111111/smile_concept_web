import 'package:flutter/material.dart';

import '../../../../data/models/branch/branch_model.dart';
import '../../../theme/app_colors.dart';

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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(
                        _nameCtrl,
                        'Branch Name *',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Branch name is required';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _field(_codeCtrl, 'Branch Code'),
                      const SizedBox(height: 14),
                      _field(_addressCtrl, 'Address'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _field(_cityCtrl, 'City')),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_provinceCtrl, 'Province')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(_phoneCtrl, 'Phone'),
                      const SizedBox(height: 14),
                      _field(_emailCtrl, 'Email'),
                      const SizedBox(height: 14),
                      _field(_hoursCtrl, 'Opening Hours e.g. 9AM–6PM'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _isActive,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEdit ? Icons.edit : Icons.add_business,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            _isEdit ? 'Edit Branch' : 'Create New Branch',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _submit,
            child: Text(
              _isEdit ? 'Update' : 'Create',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF10B981),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
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