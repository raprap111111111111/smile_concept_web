import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/role_repository.dart';
import '../../../theme/app_colors.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? user;

  const UserFormDialog({
    super.key,
    this.user,
  });

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

    _nameCtrl = TextEditingController(text: user?['name']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: user?['email']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone']?.toString() ?? '');
    _passwordCtrl = TextEditingController();
    _passwordConfirmCtrl = TextEditingController();

    final roles = user?['roles'];

    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;

      if (first is Map && first['name'] != null) {
        _selectedRole = first['name'].toString();
      } else {
        _selectedRole = first.toString();
      }
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
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      _nameCtrl,
                      'Full Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _emailCtrl,
                      'Email Address',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _field(_phoneCtrl, 'Phone optional'),
                    const SizedBox(height: 14),
                    if (!_isEdit) ...[
                      _field(
                        _passwordCtrl,
                        'Password',
                        obscure: true,
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _passwordConfirmCtrl,
                        'Confirm Password',
                        obscure: true,
                        validator: (value) {
                          if (value != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    rolesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text(
                        'Roles error',
                        style: TextStyle(color: Colors.red),
                      ),
                      data: (roles) {
                        final staffRoles = roles.where((role) {
                          return role['name']?.toString() != 'patient';
                        }).toList();

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: AppColors.surfaceDark,
                              value: _selectedRole,
                              hint: const Text(
                                'Select Role',
                                style: TextStyle(color: Colors.white38),
                              ),
                              items: staffRoles.map((role) {
                                final name = role['name'].toString();

                                return DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(
                                    name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedRole = value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Active',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _isActive,
                      activeThumbColor: const Color(0xFF06B6D4),
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                  ],
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
            Color(0xFF06B6D4),
            Color(0xFF3B82F6),
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
            _isEdit ? Icons.edit : Icons.person_add,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            _isEdit ? 'Edit User' : 'Create New User',
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
              backgroundColor: const Color(0xFF06B6D4),
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
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
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
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF06B6D4),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'is_active': _isActive,
      if (_selectedRole != null) 'role': _selectedRole,
      if (!_isEdit) ...{
        'password': _passwordCtrl.text,
        'password_confirmation': _passwordConfirmCtrl.text,
      },
    };

    Navigator.pop(context, data);
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
