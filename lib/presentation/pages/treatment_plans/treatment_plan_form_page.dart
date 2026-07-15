// lib/presentation/pages/treatment_plans/treatment_plan_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/patient/patient_model.dart';
import '../../../data/models/treatment/treatment_plan_model.dart';
import '../../../data/repositories/treatment_plan_repository.dart';
import '../../providers/doctor/doctor_list_provider.dart';
import '../../providers/patient/patient_search_provider.dart';
import '../../providers/treatment/treatment_provider.dart';
import 'widgets/dashed_add_button.dart';
import 'widgets/dropdown_states.dart';
import 'widgets/empty_catalog_banner.dart';
import 'widgets/form_section_card.dart';
import 'widgets/grand_total_bar.dart';
import 'widgets/patient_picker_field.dart';
import 'widgets/plan_item_card.dart';

class TreatmentPlanFormPage extends ConsumerStatefulWidget {
  final int? patientId;
  final int? doctorId;

  const TreatmentPlanFormPage({super.key, this.patientId, this.doctorId});

  @override
  ConsumerState<TreatmentPlanFormPage> createState() =>
      _TreatmentPlanFormPageState();
}

class _TreatmentPlanFormPageState
    extends ConsumerState<TreatmentPlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedDoctorId;
  PatientModel? _selectedPatient;
  bool _patientError = false;
  bool _isSubmitting = false;

  int? get _selectedPatientId => _selectedPatient?.userId;

  final List<TreatmentPlanItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.doctorId;
    _addItem();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treatmentProvider.notifier).loadTreatments();

      // Preload patient if ID was passed in via navigation
      if (widget.patientId != null) {
        _preloadPatient(widget.patientId!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _preloadPatient(int userId) async {
    try {
      final patients =
          await ref.read(patientSearchProvider('').future);
      final match = patients.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('Patient not found in list'),
      );
      if (mounted) setState(() => _selectedPatient = match);
    } catch (_) {
      // Silently fail — admin can still pick manually
    }
  }

  void _addItem() => setState(() => _items.add(TreatmentPlanItemForm()));

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _moveItem(int index, int dir) {
    final target = index + dir;
    if (target < 0 || target >= _items.length) return;
    setState(() {
      final m = _items.removeAt(index);
      _items.insert(target, m);
    });
  }

  double get _grandTotal =>
      _items.fold(0.0, (sum, i) => sum + i.subtotal);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill all required fields', Colors.red);
      return;
    }

    if (_selectedPatient == null) {
      setState(() => _patientError = true);
      _showSnack('Please select a patient', Colors.red);
      return;
    }
    if (_selectedDoctorId == null) {
      _showSnack('Please select a doctor', Colors.red);
      return;
    }
    if (_items.isEmpty) {
      _showSnack('Add at least one treatment item', Colors.red);
      return;
    }

    bool itemsValid = true;
    for (final i in _items) {
      if (i.selectedTreatment == null) {
        i.treatmentError = true;
        itemsValid = false;
      } else {
        i.treatmentError = false;
      }
    }
    if (!itemsValid) {
      setState(() {});
      _showSnack(
          'Please select a treatment for every item', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final itemsPayload = [
        for (int idx = 0; idx < _items.length; idx++)
          _items[idx].toPayload(idx + 1),
      ];

      final notes = _notesController.text.trim();

      final repo = ref.read(treatmentPlanRepositoryProvider);
      await repo.create(
        userId: _selectedPatientId!,
        doctorId: _selectedDoctorId!,
        name: _nameController.text.trim(),
        items: itemsPayload,
        status: 'proposed',
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        _showSnack('Treatment plan created successfully', Colors.green);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
            e.toString().replaceAll('Exception: ', ''), Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                color == Colors.green
                    ? Icons.check_circle
                    : Icons.error_outline,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treatmentState = ref.watch(treatmentProvider);
    final doctorsAsync = ref.watch(doctorSimpleListProvider);
    final theme = Theme.of(context);
    final catalogEmpty = !treatmentState.isListLoading &&
        treatmentState.treatments.isEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('New Treatment Plan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══════ Section 1: Plan Info ═══════
            FormSectionCard(
              icon: Icons.assignment_outlined,
              title: 'Plan Information',
              subtitle: 'Basic details about this treatment plan',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Plan Name *',
                      hintText: "e.g. John's Dental Restoration",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'General notes about the plan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            // ═══════ Section 2: Participants ═══════
            FormSectionCard(
              icon: Icons.groups_outlined,
              title: 'Participants',
              subtitle: 'Who is this treatment plan for?',
              child: Column(
                children: [
                  // Patient — searchable picker (scales to thousands)
                  PatientPickerField(
                    selected: _selectedPatient,
                    hasError: _patientError,
                    onPicked: (p) => setState(() {
                      _selectedPatient = p;
                      _patientError = false;
                    }),
                  ),
                  const SizedBox(height: 14),
                  // Doctor — normal dropdown (usually smaller list)
                  doctorsAsync.when(
                    loading: () =>
                        const DropdownLoading(label: 'Doctor *'),
                    error: (e, _) => DropdownError(
                      label: 'Doctor *',
                      error: e.toString(),
                      onRetry: () =>
                          ref.invalidate(doctorSimpleListProvider),
                    ),
                    data: (doctors) {
                      final validSelected = doctors
                              .any((d) => d.id == _selectedDoctorId)
                          ? _selectedDoctorId
                          : null;
                      return DropdownButtonFormField<int>(
                        initialValue: validSelected,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Doctor *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                              Icons.medical_services_outlined),
                        ),
                        hint: const Text('Select doctor'),
                        items: doctors
                            .map((d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(d.displayLabel,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedDoctorId = v),
                        validator: (v) => v == null
                            ? 'Please select a doctor'
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            // ═══════ Section 3: Treatment Items ═══════
            FormSectionCard(
              icon: Icons.medical_information_outlined,
              title: 'Treatment Steps',
              subtitle: 'Add the treatments included in this plan',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_items.length} step${_items.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (catalogEmpty)
                    const EmptyCatalogBanner()
                  else ...[
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return PlanItemCard(
                        index: index,
                        item: item,
                        availableTreatments: treatmentState.treatments,
                        isLoading: treatmentState.isListLoading,
                        onMoveUp:
                            index > 0 ? () => _moveItem(index, -1) : null,
                        onMoveDown: index < _items.length - 1
                            ? () => _moveItem(index, 1)
                            : null,
                        onRemove: _items.length > 1
                            ? () => _removeItem(index)
                            : null,
                        onChanged: () => setState(() {}),
                      );
                    }),
                    const SizedBox(height: 4),
                    DashedAddButton(onTap: _addItem),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 80), // space for sticky bottom bar
          ],
        ),
      ),
      bottomNavigationBar: GrandTotalBar(
        total: _grandTotal,
        itemCount: _items.length,
        isSubmitting: _isSubmitting,
        onSubmit: _submit,
      ),
    );
  }
}