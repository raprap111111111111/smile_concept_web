// lib/presentation/pages/prescriptions/prescription_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/prescription/prescription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/form/doctor_dropdown.dart';
import 'widgets/form/empty_medicine_state.dart';
import 'widgets/form/medicine_item_card.dart';  
import 'widgets/form/medicine_item_form.dart';   
import 'widgets/form/patient_dropdown.dart';
import 'widgets/form/prescription_form_header.dart';
import 'widgets/form/prescription_form_section.dart';
import '/presentation/widgets/shared//access_denied_view.dart';
import '/presentation/widgets/shared//app_snackbar.dart';       

class PrescriptionFormPage extends ConsumerStatefulWidget {
  final int? patientId;
  final int? appointmentId;

  const PrescriptionFormPage({
    super.key,
    this.patientId,
    this.appointmentId,
  });

  @override
  ConsumerState<PrescriptionFormPage> createState() =>
      _PrescriptionFormPageState();
}

class _PrescriptionFormPageState
    extends ConsumerState<PrescriptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<MedicineItemForm> _items = [];

  int? _selectedDoctorId;
  int? _selectedPatientId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addItem();
    _selectedPatientId = widget.patientId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── Item management ──────────────────────────────────────
  void _addItem() {
    setState(() => _items.add(MedicineItemForm()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  // ── Submit ───────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _createPrescription();
      await ref
          .read(prescriptionProvider.notifier)
          .loadPrescriptions(forceRefresh: true);

      if (mounted) {
        AppSnackbar.show(
            context, 'Prescription created successfully');
        context.pop();
      }
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validate() {
    final authState = ref.read(authStateProvider);
    if (!authState.canCreatePrescription) {
      AppSnackbar.show(
        context,
        'You do not have permission to create prescriptions.',
        isError: true,
      );
      return false;
    }

    if (!_formKey.currentState!.validate()) return false;

    if (_selectedDoctorId == null) {
      AppSnackbar.show(context, 'Please select a doctor.',
          isError: true);
      return false;
    }
    if (_selectedPatientId == null) {
      AppSnackbar.show(context, 'Please select a patient.',
          isError: true);
      return false;
    }
    if (_items.isEmpty) {
      AppSnackbar.show(context,
          'Please add at least one medicine.',
          isError: true);
      return false;
    }

    return true;
  }

  Future<void> _createPrescription() async {
    final remote = ref.read(prescriptionRemoteDataSourceProvider);
    final itemsPayload =
        _items.map((item) => item.toPayload()).toList();

    await remote.createPrescription(
      doctorId: _selectedDoctorId!,
      userId: _selectedPatientId!,
      appointmentId: widget.appointmentId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      items: itemsPayload,
    );
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (!authState.canCreatePrescription) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(canSubmit: false),
        body: AccessDeniedView(onBack: () => context.pop()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(canSubmit: true),
      body: _buildBody(authState.role),
    );
  }

  Widget _buildBody(String role) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrescriptionFormHeader(role: role),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildAssignmentSection(),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildMedicinesSection(),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildNotesSection(),
                const SizedBox(height: AppDimensions.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sections ─────────────────────────────────────────────
  Widget _buildAssignmentSection() {
    return PrescriptionFormSection(
      number: '1',
      title: 'Assignment',
      subtitle:
          'Select the doctor and patient for this prescription',
      icon: Icons.assignment_ind_outlined,
      children: [
        DoctorDropdown(
          selectedDoctorId: _selectedDoctorId,
          onChanged: (val) =>
              setState(() => _selectedDoctorId = val),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        PatientDropdown(
          selectedPatientId: _selectedPatientId,
          onChanged: (val) =>
              setState(() => _selectedPatientId = val),
        ),
      ],
    );
  }

  Widget _buildMedicinesSection() {
    return PrescriptionFormSection(
      number: '2',
      title: 'Medicines',
      subtitle: 'Add medicines with dosage and instructions',
      icon: Icons.medication_outlined,
      trailing: _buildAddMedicineButton(),
      children: [
        if (_items.isEmpty)
          EmptyMedicineState(onAdd: _addItem)
        else
          ..._buildMedicineList(),
      ],
    );
  }

  Widget _buildAddMedicineButton() {
    return FilledButton.icon(
      onPressed: _addItem,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentWithOpacity(0.15),
        foregroundColor: AppColors.primaryDark,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add Medicine'),
    );
  }

  List<Widget> _buildMedicineList() {
    return List.generate(
      _items.length,
      (index) => Padding(
        padding: EdgeInsets.only(
          bottom: index == _items.length - 1
              ? 0
              : AppDimensions.paddingMedium,
        ),
        child: MedicineItemCard(
          item: _items[index],
          index: index,
          onRemove:
              _items.length > 1 ? () => _removeItem(index) : null,
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return PrescriptionFormSection(
      number: '3',
      title: "Doctor's Notes",
      subtitle: 'Optional notes or general instructions',
      icon: Icons.sticky_note_2_outlined,
      isOptional: true,
      children: [
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.ink),
          decoration: const InputDecoration(
            hintText:
                'Add any notes or instructions for the patient...',
          ),
        ),
      ],
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar({required bool canSubmit}) {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back,
            color: AppColors.textSecondary),
      ),
      title: const Text('New Prescription',
          style: AppTextStyles.titleLarge),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.line),
      ),
      actions: canSubmit ? [_buildSaveButton()] : null,
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding:
          const EdgeInsets.only(right: AppDimensions.paddingLarge),
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check, size: 18),
        label: Text(
          _isSubmitting ? 'Saving...' : 'Save Prescription',
          style:
              AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}