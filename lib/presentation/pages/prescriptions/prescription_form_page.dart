// lib/presentation/pages/prescriptions/prescription_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/doctor/doctor_list_provider.dart';
import '../../providers/patient/patient_list_provider.dart';
import '../../providers/prescription/prescription_provider.dart';

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

  int? _selectedDoctorId;
  int? _selectedPatientId;

  final _notesController = TextEditingController();
  final List<_MedicineItemForm> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addItem();

    if (widget.patientId != null) {
      _selectedPatientId = widget.patientId;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_MedicineItemForm()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  // ─── Permission-Guarded Submit ─────────────────────────────
  Future<void> _submit() async {
    // ✅ STEP 1: RBAC check — before anything else
    final authState = ref.read(authStateProvider);
    if (!authState.canCreatePrescription) {
      _showError(
        '❌ You do not have permission to create prescriptions.',
      );
      return;
    }

    // ✅ STEP 2: Form validation
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctorId == null) {
      _showError('Please select a doctor.');
      return;
    }
    if (_selectedPatientId == null) {
      _showError('Please select a patient.');
      return;
    }
    if (_items.isEmpty) {
      _showError('Please add at least one medicine.');
      return;
    }

    // ✅ STEP 3: Execute
    setState(() => _isSubmitting = true);

    try {
      final remote = ref.read(prescriptionRemoteDataSourceProvider);

      final itemsPayload = _items.map((item) {
        return {
          'medicine_name': item.medicineController.text.trim(),
          'dosage':        item.dosageController.text.trim(),
          'frequency':     item.frequencyController.text.trim(),
          'duration_days':
              int.parse(item.durationController.text.trim()),
          if (item.instructionsController.text.trim().isNotEmpty)
            'instructions':
                item.instructionsController.text.trim(),
        };
      }).toList();

      await remote.createPrescription(
        doctorId:      _selectedDoctorId!,
        userId:        _selectedPatientId!,
        appointmentId: widget.appointmentId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: itemsPayload,
      );

      await ref
          .read(prescriptionProvider.notifier)
          .loadPrescriptions(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Prescription created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ✅ Watch auth for permission-aware UI
    final authState    = ref.watch(authStateProvider);
    final canCreate    = authState.canCreatePrescription;

    // ── Watch data providers ────────────────────────────────
    final doctorsAsync  = ref.watch(doctorSimpleListProvider);
    final patientsState = ref.watch(patientListProvider);

    // ✅ Show access denied UI if no permission
    if (!canCreate) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Prescription')),
        body: _buildAccessDenied(context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Prescription')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Role badge (for context) ─────────────────
              if (authState.role != null)
                _RoleBadge(role: authState.role!),

              const SizedBox(height: 16),

              // ─── Doctor Dropdown ─────────────────────────
              doctorsAsync.when(
                loading: () => const _LoadingField(
                  label: 'Loading doctors...',
                ),
                error: (e, _) => _ErrorField(
                  label: 'Failed to load doctors',
                  error: e.toString(),
                  onRetry: () =>
                      ref.invalidate(doctorSimpleListProvider),
                ),
                data: (doctors) {
                  if (doctors.isEmpty) {
                    return const _EmptyField(
                      label: 'No doctors available',
                    );
                  }
                  return DropdownButtonFormField<int>(
                    value: _selectedDoctorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Doctor *',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.person_rounded),
                    ),
                    hint: const Text('Select Doctor'),
                    items: doctors.map((doc) {
                      return DropdownMenuItem<int>(
                        value: doc.id,
                        child: Text(
                          doc.displayLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDoctorId = val),
                    validator: (val) => val == null
                        ? 'Please select a doctor'
                        : null,
                  );
                },
              ),

              const SizedBox(height: 16),

              // ─── Patient Dropdown ────────────────────────
              if (patientsState.isLoading &&
                  patientsState.patients.isEmpty)
                const _LoadingField(label: 'Loading patients...')
              else if (patientsState.errorMessage != null &&
                  patientsState.patients.isEmpty)
                _ErrorField(
                  label: 'Failed to load patients',
                  error: patientsState.errorMessage!,
                  onRetry: () =>
                      ref.read(patientListProvider.notifier).refresh(),
                )
              else if (patientsState.patients.isEmpty)
                const _EmptyField(label: 'No patients available')
              else
                DropdownButtonFormField<int>(
                  value: _selectedPatientId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Patient *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.face_rounded),
                  ),
                  hint: const Text('Select Patient'),
                  items: patientsState.patients.map((pat) {
                    return DropdownMenuItem<int>(
                      value: pat.userId,
                      child: Text(
                        pat.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedPatientId = val),
                  validator: (val) => val == null
                      ? 'Please select a patient'
                      : null,
                ),

              const SizedBox(height: 16),

              // ─── Notes ───────────────────────────────────
              Text(
                'Doctor Notes (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add any notes for the patient...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Medicines Header ─────────────────────────
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medicines',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medicine'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_items.isEmpty)
                Center(
                  child: Text(
                    'No medicines added yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                ...List.generate(_items.length, (index) {
                  return _MedicineItemCard(
                    item:     _items[index],
                    index:    index,
                    onRemove: _items.length > 1
                        ? () => _removeItem(index)
                        : null,
                  );
                }),

              const SizedBox(height: 32),

              // ─── Submit Button ────────────────────────────
              SizedBox(
                width:  double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width:  22,
                          height: 22,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Prescription',
                          style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Access Denied UI ─────────────────────────────────────────
  Widget _buildAccessDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size:  72,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      Colors.red.shade400,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have permission to create prescriptions.\n'
              'Only dentists can create prescriptions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon:  const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role Badge Widget ─────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    return switch (role) {
      'super-admin'  => Colors.purple,
      'admin'        => Colors.blue,
      'dentist'      => Colors.teal,
      'receptionist' => Colors.orange,
      'patient'      => Colors.green,
      _              => Colors.grey,
    };
  }

  IconData get _icon {
    return switch (role) {
      'super-admin'  => Icons.admin_panel_settings,
      'admin'        => Icons.manage_accounts,
      'dentist'      => Icons.medical_services_rounded,
      'receptionist' => Icons.support_agent_rounded,
      'patient'      => Icons.person_rounded,
      _              => Icons.person_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
          color: _color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w700,
              color:      _color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper State Widgets ─────────────────────────────────────
class _LoadingField extends StatelessWidget {
  final String label;
  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border:       Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(
            width:  20,
            height: 20,
            child:  CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _ErrorField extends StatelessWidget {
  final String label;
  final String error;
  final VoidCallback onRetry;

  const _ErrorField({
    required this.label,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border:       Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          TextButton(
            onPressed: onRetry,
            child:     const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyField extends StatelessWidget {
  final String label;
  const _EmptyField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border:       Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

// ─── Medicine Item Data ───────────────────────────────────────
class _MedicineItemForm {
  final medicineController    = TextEditingController();
  final dosageController      = TextEditingController();
  final frequencyController   = TextEditingController();
  final durationController    = TextEditingController();
  final instructionsController = TextEditingController();

  void dispose() {
    medicineController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }
}

// ─── Medicine Item Card ───────────────────────────────────────
class _MedicineItemCard extends StatelessWidget {
  final _MedicineItemForm item;
  final int index;
  final VoidCallback? onRemove;

  const _MedicineItemCard({
    required this.item,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin:     const EdgeInsets.only(bottom: 16),
      elevation:  0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ──────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.bold,
                      color:      colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Medicine ${index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Remove',
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Medicine Name ────────────────────────────
            TextFormField(
              controller: item.medicineController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name *',
                hintText:  'e.g., Amoxicillin',
                border:    OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 12),

            // ── Dosage + Frequency ───────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage *',
                      hintText:  'e.g., 500mg',
                      border:    OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Required'
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.frequencyController,
                    decoration: const InputDecoration(
                      labelText: 'Frequency *',
                      hintText:  'e.g., 3x daily',
                      border:    OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Required'
                            : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Duration ─────────────────────────────────
            TextFormField(
              controller:  item.durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText:  'Duration (days) *',
                hintText:   'e.g., 7',
                border:     OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null)
                  return 'Must be a number';
                if (int.parse(v.trim()) < 1)
                  return 'Must be at least 1';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // ── Instructions ─────────────────────────────
            TextFormField(
              controller: item.instructionsController,
              maxLines:   2,
              decoration: const InputDecoration(
                labelText: 'Instructions (Optional)',
                hintText:  'e.g., Take after meal',
                border:    OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}