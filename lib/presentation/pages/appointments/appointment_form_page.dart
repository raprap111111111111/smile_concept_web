// lib/presentation/pages/appointments/appointment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../data/models/appointment/appointment_model.dart';
import '../../../data/models/appointment/appointment_request.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/branch/branch_provider.dart';
import 'widgets/patient_search_field.dart';
import 'widgets/time_slot_picker.dart';

class AppointmentFormPage extends ConsumerStatefulWidget {
  final AppointmentModel? existingAppointment;

  const AppointmentFormPage({
    super.key,
    this.existingAppointment,
  });

  @override
  ConsumerState<AppointmentFormPage> createState() =>
      _AppointmentFormPageState();
}

class _AppointmentFormPageState extends ConsumerState<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  int? _doctorId;
  int? _branchId;
  int? _userId;
  String? _selectedPatientName;
  DateTime? _selectedDate;
  String _status = 'pending';
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingAppointment != null;

  @override
  void initState() {
    super.initState();

    final appointment = widget.existingAppointment;

    if (appointment != null) {
      _doctorId = appointment.doctorId;
      _branchId = appointment.branchId;
      _userId = appointment.userId;
      _selectedDate = appointment.startTime;
      _status = appointment.status.name;
      _selectedPatientName = appointment.user?.name;
      _reasonController.text = appointment.reasonForVisit ?? '';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_doctorId == null || _branchId == null || _selectedDate == null) {
      return;
    }

    await ref.read(availabilityNotifierProvider.notifier).fetchSlots(
          doctorId: _doctorId!,
          branchId: _branchId!,
          date: _selectedDate!,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    ref.read(availabilityNotifierProvider.notifier).clearSlots();

    await _fetchSlots();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(authStateProvider).user;

    final canCreateSelf = permissionService.can(
      AppPermissions.appointmentCreate,
    );

    final canCreateForOthers = permissionService.can(
      AppPermissions.appointmentCreateForOthers,
    );

    final canUpdateStatus = permissionService.can(
      AppPermissions.appointmentUpdateStatus,
    );

    if (!canCreateSelf && !canCreateForOthers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to create appointments.'),
        ),
      );
      return;
    }

    final slotState = ref.read(availabilityNotifierProvider);
    final selectedSlot = slotState.selectedSlot;

    if (selectedSlot == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot.'),
        ),
      );
      return;
    }

    if (!_isEditing && canCreateForOthers && _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(appointmentRepositoryProvider);

      AppointmentModel result;

      final reasonForVisit = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();

      if (_isEditing) {
        final existing = widget.existingAppointment!;

        final targetUserId = canCreateForOthers
            ? (_userId ?? existing.userId)
            : existing.userId;

        final request = AppointmentRequest(
          doctorId: _doctorId ?? existing.doctorId,
          branchId: _branchId ?? existing.branchId,
          startTime: selectedSlot != null
              ? selectedSlot.startDateTime
              : existing.startTime,
          endTime:
              selectedSlot != null ? selectedSlot.endDateTime : existing.endTime,
          userId: targetUserId,
          status: canUpdateStatus ? _status : existing.status.name,
          reasonForVisit: reasonForVisit,
        );

        debugPrint('Updating appointment payload: ${request.toJson()}');

        result = await repo.updateAppointment(
          id: existing.id,
          request: request,
        );
      } else {
        final targetUserId = canCreateForOthers ? _userId : currentUser?.id;

        final request = AppointmentRequest(
          doctorId: _doctorId!,
          branchId: _branchId!,
          startTime: selectedSlot!.startDateTime,
          endTime: selectedSlot.endDateTime,
          userId: targetUserId,
          status: _status,
          reasonForVisit: reasonForVisit,
        );

        debugPrint('Can create for others: $canCreateForOthers');
        debugPrint('Selected patient name: $_selectedPatientName');
        debugPrint('Selected patient user_id: $_userId');
        debugPrint('Current auth user_id: ${currentUser?.id}');
        debugPrint('Creating appointment payload: ${request.toJson()}');

        result = await repo.createAppointment(request);
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availState = ref.watch(availabilityNotifierProvider);

    final doctorsAsync = ref.watch(doctorsProvider);
    final branchesAsync = ref.watch(branchesProvider);

    final permissionService = ref.watch(permissionServiceProvider);
    final currentUser = ref.watch(authStateProvider).user;

    /*
    |--------------------------------------------------------------------------
    | This is the exact frontend equivalent of:
    | return $user->can('appointment.create-for-others');
    |--------------------------------------------------------------------------
    */
    final canCreateForOthers = permissionService.can(
      AppPermissions.appointmentCreateForOthers,
    );

    final canUpdateStatus = permissionService.can(
      AppPermissions.appointmentUpdateStatus,
    );

    debugPrint('Appointment form permissions:');
    debugPrint('Role: ${currentUser?.role}');
    debugPrint('Permissions: ${currentUser?.permissions}');
    debugPrint('Can create for others: $canCreateForOthers');

    final dateLabel = _selectedDate != null
        ? DateFormat('EEE, MMM dd yyyy').format(_selectedDate!)
        : 'Select Date';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Appointment' : 'New Appointment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Label('Doctor *'),
              doctorsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Failed to load doctors: $error',
                  style: const TextStyle(color: Colors.red),
                ),
                data: (doctors) => DropdownButtonFormField<int>(
                  initialValue: _doctorId,
                  decoration: _inputDecor('Select Doctor'),
                  items: doctors.map((doctor) {
                    final id = doctor['id'] as int;
                    final name = doctor['name']?.toString() ??
                        (doctor['user'] as Map?)?['name']?.toString() ??
                        'Doctor #$id';

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _doctorId = value;
                    });

                    ref
                        .read(availabilityNotifierProvider.notifier)
                        .clearSlots();

                    _fetchSlots();
                  },
                  validator: (value) =>
                      value == null ? 'Doctor is required' : null,
                ),
              ),

              const SizedBox(height: 16),

              const _Label('Branch *'),
              branchesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Failed to load branches: $error',
                  style: const TextStyle(color: Colors.red),
                ),
                data: (branches) => DropdownButtonFormField<int>(
                  initialValue: _branchId,
                  decoration: _inputDecor('Select Branch'),
                  items: branches.map((branch) {
                    return DropdownMenuItem<int>(
                      value: branch.id,
                      child: Text(branch.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _branchId = value;
                    });

                    ref
                        .read(availabilityNotifierProvider.notifier)
                        .clearSlots();

                    _fetchSlots();
                  },
                  validator: (value) =>
                      value == null ? 'Branch is required' : null,
                ),
              ),

              const SizedBox(height: 16),

              /*
              |--------------------------------------------------------------------------
              | Patient search is only visible with appointment.create-for-others
              |--------------------------------------------------------------------------
              */
              if (canCreateForOthers) ...[
                const _Label('Patient *'),
                PatientSearchField(
                  selectedPatientId: _userId,
                  selectedPatientName: _selectedPatientName,
                  onPatientSelected: (PatientModel? patient) {
                    setState(() {
                      _userId = patient?.userId;
                      _selectedPatientName = patient?.name;
                    });

                    debugPrint('Selected patient: $_selectedPatientName');
                    debugPrint('Selected patient user_id: $_userId');
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                const _Label('Patient'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentUser?.name ?? 'Current user',
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const _Label('Reason for Visit'),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: _inputDecor(
                  'e.g., Toothache, Cleaning, Check-up',
                ),
              ),

              const SizedBox(height: 16),

              const _Label('Date *'),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dateLabel),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_selectedDate != null) ...[
                const _Label('Available Time Slots *'),
                TimeSlotPicker(
                  state: availState,
                  onSlotSelected: (slot) {
                    ref
                        .read(availabilityNotifierProvider.notifier)
                        .selectSlot(slot);
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_isEditing && canUpdateStatus) ...[
                const _Label('Status'),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _inputDecor('Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value ?? 'pending');
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Update Appointment'
                            : 'Book Appointment',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}