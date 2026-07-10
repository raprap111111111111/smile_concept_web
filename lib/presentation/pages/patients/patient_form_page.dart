// lib/presentation/pages/patients/patient_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../providers/patient/patient_list_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';

class PatientFormPage extends ConsumerStatefulWidget {
  final int? patientId; // null = create, non-null = edit

  const PatientFormPage({super.key, this.patientId});

  bool get isEditing => patientId != null;

  @override
  ConsumerState<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends ConsumerState<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  // ─── Personal ──────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(); // ✅ NEW

  // ─── Medical ───────────────────────────────────
  String? _bloodType; // ✅ Changed to dropdown
  final _allergiesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  // ─── Emergency ─────────────────────────────────
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // ─── Special conditions ────────────────────────
  bool _requiresEpinephrineFree = false;
  bool _hasCardiacConditions = false;
  bool _isPregnant = false;
  bool _hasBleedingDisorders = false;

  bool _isSubmitting = false;
  bool _isLoadingData = false;
  bool _obscurePassword = true;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadPatientData();
    }
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoadingData = true);
    try {
      final repo = ref.read(patientRepositoryProvider);
      final patient = await repo.getById(widget.patientId!);

      _nameController.text = patient.name;
      _emailController.text = patient.email;
      _phoneController.text = patient.phone ?? '';

      // ✅ patientProfile is a non-null getter
      final profile = patient.patientProfile;
      _bloodType = _bloodTypes.contains(profile.bloodType)
          ? profile.bloodType
          : null;
      _allergiesController.text = profile.allergies ?? '';
      _medicalHistoryController.text = profile.medicalHistory ?? '';
      _emergencyNameController.text = profile.emergencyContactName ?? '';
      _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
      _requiresEpinephrineFree = profile.requiresEpinephrineFreeAnesthesia;
      _hasCardiacConditions = profile.hasCardiacConditions;
      _isPregnant = profile.isPregnant;
      _hasBleedingDisorders = profile.hasBleedingDisorders;
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load patient: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(patientRepositoryProvider);

      // ─── Build payload ─────────────────────────
      final data = <String, dynamic>{
        // User fields (only send if non-empty)
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),

        // Medical fields
        if (_bloodType != null && _bloodType!.isNotEmpty)
          'blood_type': _bloodType,
        if (_allergiesController.text.trim().isNotEmpty)
          'allergies': _allergiesController.text.trim(),
        if (_medicalHistoryController.text.trim().isNotEmpty)
          'medical_history': _medicalHistoryController.text.trim(),
        if (_emergencyNameController.text.trim().isNotEmpty)
          'emergency_contact_name': _emergencyNameController.text.trim(),
        if (_emergencyPhoneController.text.trim().isNotEmpty)
          'emergency_contact_phone': _emergencyPhoneController.text.trim(),

        // Flags always included
        'requires_epinephrine_free_anesthesia': _requiresEpinephrineFree,
        'has_cardiac_conditions': _hasCardiacConditions,
        'is_pregnant': _isPregnant,
        'has_bleeding_disorders': _hasBleedingDisorders,
      };

      // ✅ Password only for CREATE (and only if provided)
      if (!widget.isEditing && _passwordController.text.trim().isNotEmpty) {
        data['password'] = _passwordController.text.trim();
      }

      if (widget.isEditing) {
        await repo.update(widget.patientId!, data);
      } else {
        await repo.create(data);
      }

      // Refresh the list
      ref.read(patientListProvider.notifier).refresh();

      if (mounted) {
        _showSnackBar(
          widget.isEditing
              ? '✅ Patient updated successfully'
              : '✅ Patient created successfully',
        );
        context.goNamed(RouteNames.patients);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ─────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.goNamed(RouteNames.patients),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEditing ? 'Edit Patient' : 'New Patient',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Personal Info ──────────────────────
              _sectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline,
                children: [
                  _textField(
                    controller: _nameController,
                    label: 'Full Name',
                    required: true,
                  ),
                  _textField(
                    controller: _emailController,
                    label: 'Email',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  _textField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                  ),

                  // ✅ Password field ONLY in create mode
                  if (!widget.isEditing) _buildPasswordField(),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Medical Info ───────────────────────
              _sectionCard(
                title: 'Medical Information',
                icon: Icons.medical_information_outlined,
                children: [
                  _buildBloodTypeDropdown(), // ✅ Dropdown now
                  _textField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    maxLines: 3,
                  ),
                  _textField(
                    controller: _medicalHistoryController,
                    label: 'Medical History',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Emergency Contact ──────────────────
              _sectionCard(
                title: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                children: [
                  _textField(
                    controller: _emergencyNameController,
                    label: 'Contact Name',
                  ),
                  _textField(
                    controller: _emergencyPhoneController,
                    label: 'Contact Phone',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Special Conditions ─────────────────
              _sectionCard(
                title: 'Special Conditions',
                icon: Icons.warning_amber_outlined,
                children: [
                  _switchTile(
                    'Requires Epinephrine-free Anesthesia',
                    _requiresEpinephrineFree,
                    (v) => setState(() => _requiresEpinephrineFree = v),
                  ),
                  _switchTile(
                    'Has Cardiac Conditions',
                    _hasCardiacConditions,
                    (v) => setState(() => _hasCardiacConditions = v),
                  ),
                  _switchTile(
                    'Is Pregnant',
                    _isPregnant,
                    (v) => setState(() => _isPregnant = v),
                  ),
                  _switchTile(
                    'Has Bleeding Disorders',
                    _hasBleedingDisorders,
                    (v) => setState(() => _hasBleedingDisorders = v),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Actions ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.goNamed(RouteNames.patients),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'UPDATE PATIENT'
                                  : 'CREATE PATIENT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Password Field ─────────────────────────────────
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Password (optional — auto-generated if empty)',
          labelStyle: const TextStyle(color: Colors.white70),
          helperText: 'Minimum 8 characters if set',
          helperStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator: (v) {
          if (v != null && v.isNotEmpty && v.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
      ),
    );
  }

  // ─── Blood Type Dropdown ────────────────────────────
  Widget _buildBloodTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _bloodType,
        dropdownColor: AppColors.surfaceDark,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Blood Type',
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        hint: const Text(
          'Select blood type',
          style: TextStyle(color: Colors.white38),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text(
              '— None —',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ..._bloodTypes.map(
            (v) => DropdownMenuItem(value: v, child: Text(v)),
          ),
        ],
        onChanged: (v) => setState(() => _bloodType = v),
      ),
    );
  }

  // ─── Widget Helpers ─────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null
                : null),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }
}