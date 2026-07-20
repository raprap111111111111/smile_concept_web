// lib/presentation/pages/patients/patient_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../providers/patient/patient_list_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/patient_form_field.dart';
import 'widgets/patient_page_header.dart';
import 'widgets/patient_section_card.dart';

class PatientFormPage extends ConsumerStatefulWidget {
  final int? patientId;
  const PatientFormPage({super.key, this.patientId});

  bool get isEditing => patientId != null;

  @override
  ConsumerState<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends ConsumerState<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _bloodType;
  final _allergiesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

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
    if (widget.isEditing) _loadPatientData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoadingData = true);
    try {
      final repo = ref.read(patientRepositoryProvider);
      final patient = await repo.getById(widget.patientId!);

      final parts = patient.name.trim().split(RegExp(r'\s+'));
      _firstNameController.text = parts.isEmpty ? '' : parts.first;
      _lastNameController.text =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _emailController.text = patient.email;
      _phoneController.text = patient.phone ?? '';

      final profile = patient.patientProfile;
      _bloodType =
          _bloodTypes.contains(profile.bloodType) ? profile.bloodType : null;
      _allergiesController.text = profile.allergies ?? '';
      _medicalHistoryController.text = profile.medicalHistory ?? '';
      _emergencyNameController.text = profile.emergencyContactName ?? '';
      _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
      _requiresEpinephrineFree = profile.requiresEpinephrineFreeAnesthesia;
      _hasCardiacConditions = profile.hasCardiacConditions;
      _isPregnant = profile.isPregnant;
      _hasBleedingDisorders = profile.hasBleedingDisorders;
    } catch (e) {
      if (mounted) _showSnackBar('Failed to load patient: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(patientRepositoryProvider);
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();

      final data = <String, dynamic>{
        'name': fullName,
        'email': _emailController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
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
        'requires_epinephrine_free_anesthesia': _requiresEpinephrineFree,
        'has_cardiac_conditions': _hasCardiacConditions,
        'is_pregnant': _isPregnant,
        'has_bleeding_disorders': _hasBleedingDisorders,
      };

      if (!widget.isEditing && _passwordController.text.trim().isNotEmpty) {
        data['password'] = _passwordController.text.trim();
      }

      if (widget.isEditing) {
        await repo.update(widget.patientId!, data);
      } else {
        await repo.create(data);
      }

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
      if (mounted) _showSnackBar('❌ $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
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

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatientPageHeader(
                title: widget.isEditing ? 'Edit Patient' : 'New Patient',
                onBack: () => context.goNamed(RouteNames.patients),
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              // Personal
              PatientSectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline,
                children: [
                  PatientFormField(
                    controller: _firstNameController,
                    label: 'First Name',
                    required: true,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => Validators.validateName(v,
                        fieldName: 'First name'),
                  ),
                  PatientFormField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    required: !widget.isEditing,
                    prefixIcon: Icons.person_outline,
                    validator: widget.isEditing
                        ? null
                        : (v) => Validators.validateName(v,
                            fieldName: 'Last name'),
                  ),
                  PatientFormField(
                    controller: _emailController,
                    label: 'Email',
                    required: true,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  PatientFormField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  if (!widget.isEditing)
                    _PasswordField(
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      onToggle: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Medical
              PatientSectionCard(
                title: 'Medical Information',
                icon: Icons.medical_information_outlined,
                children: [
                  _BloodTypeDropdown(
                    value: _bloodType,
                    bloodTypes: _bloodTypes,
                    onChanged: (v) => setState(() => _bloodType = v),
                  ),
                  PatientFormField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    maxLines: 3,
                  ),
                  PatientFormField(
                    controller: _medicalHistoryController,
                    label: 'Medical History',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Emergency
              PatientSectionCard(
                title: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                children: [
                  PatientFormField(
                    controller: _emergencyNameController,
                    label: 'Contact Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  PatientFormField(
                    controller: _emergencyPhoneController,
                    label: 'Contact Phone',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Special Conditions
              PatientSectionCard(
                title: 'Special Conditions',
                icon: Icons.warning_amber_outlined,
                children: [
                  _SwitchTile(
                    label: 'Requires Epinephrine-free Anesthesia',
                    value: _requiresEpinephrineFree,
                    onChanged: (v) =>
                        setState(() => _requiresEpinephrineFree = v),
                  ),
                  _SwitchTile(
                    label: 'Has Cardiac Conditions',
                    value: _hasCardiacConditions,
                    onChanged: (v) =>
                        setState(() => _hasCardiacConditions = v),
                  ),
                  _SwitchTile(
                    label: 'Is Pregnant',
                    value: _isPregnant,
                    onChanged: (v) => setState(() => _isPregnant = v),
                  ),
                  _SwitchTile(
                    label: 'Has Bleeding Disorders',
                    value: _hasBleedingDisorders,
                    onChanged: (v) =>
                        setState(() => _hasBleedingDisorders = v),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              _FormActions(
                isEditing: widget.isEditing,
                isSubmitting: _isSubmitting,
                onCancel: () => context.goNamed(RouteNames.patients),
                onSubmit: _handleSubmit,
              ),
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Password Field ────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
        decoration: InputDecoration(
          labelText: 'Password (optional — auto-generated if empty)',
          helperText: 'Minimum 8 characters if set',
          prefixIcon:
              const Icon(Icons.lock_outline, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggle,
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
}

// ── Blood Type Dropdown ───────────────────────────────────────
class _BloodTypeDropdown extends StatelessWidget {
  final String? value;
  final List<String> bloodTypes;
  final ValueChanged<String?> onChanged;

  const _BloodTypeDropdown({
    required this.value,
    required this.bloodTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: AppColors.background,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
        decoration: const InputDecoration(
          labelText: 'Blood Type',
          prefixIcon: Icon(Icons.bloodtype_outlined,
              color: AppColors.textSecondary),
        ),
        icon: const Icon(Icons.arrow_drop_down,
            color: AppColors.textSecondary),
        hint: Text(
          'Select blood type',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textTertiary),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('— None —'),
          ),
          ...bloodTypes.map(
            (v) => DropdownMenuItem(value: v, child: Text(v)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Switch Tile ───────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

// ── Form Actions ──────────────────────────────────────────────
class _FormActions extends StatelessWidget {
  final bool isEditing;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _FormActions({
    required this.isEditing,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('CANCEL'),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isEditing ? 'UPDATE PATIENT' : 'CREATE PATIENT',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}