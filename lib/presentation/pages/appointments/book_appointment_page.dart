// lib/presentation/pages/appointments/book_appointment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/appointment/appointment_request.dart';
import '../../../data/models/appointment/availability_model.dart';
import '../../../data/models/patient/patient_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../providers/appointment/appointment_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/doctor_schedule/schedule_form_providers.dart';
import '../doctor_schedules/widgets/dropdown_states.dart';
import 'widgets/patient_search_field.dart';
import 'widgets/time_slot_picker.dart';

final selectedDoctorProvider = StateProvider<int?>((ref) => null);
final selectedBranchProvider = StateProvider<int?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

class BookAppointmentPage extends ConsumerStatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  ConsumerState<BookAppointmentPage> createState() =>
      _BookAppointmentPageState();
}

class _BookAppointmentPageState extends ConsumerState<BookAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  int? _selectedPatientId;
  String? _selectedPatientName;

  @override
  void initState() {
    super.initState();

    final currentUser = ref.read(authStateProvider).user;
    _fullNameController.text = currentUser?.name ?? '';
    _mobileController.text = currentUser?.phone ?? '';
    _emailController.text = currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    final doctorId = ref.read(selectedDoctorProvider);
    final branchId = ref.read(selectedBranchProvider);
    final date = ref.read(selectedDateProvider);

    if (doctorId == null || branchId == null || date == null) return;

    await ref.read(availabilityNotifierProvider.notifier).fetchSlots(
          doctorId: doctorId,
          branchId: branchId,
          date: date,
        );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
      ref.read(availabilityNotifierProvider.notifier).clearSlots();

      await _fetchSlots();
    }
  }

  Future<void> _bookAppointment(TimeSlot slot) async {
    if (!_formKey.currentState!.validate()) return;

    final doctorId = ref.read(selectedDoctorProvider);
    final branchId = ref.read(selectedBranchProvider);
    final date = ref.read(selectedDateProvider);

    final permissionService = ref.read(permissionServiceProvider);
    final currentUser = ref.read(authStateProvider).user;

    final canCreateSelf = permissionService.can(
      Perm.appointmentCreate,
    );

    final canCreateForOthers = permissionService.can(
      Perm.appointmentCreateForOthers,
    );

    if (!canCreateSelf && !canCreateForOthers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to book appointments.'),
        ),
      );
      return;
    }

    if (doctorId == null || branchId == null || date == null) return;

    if (canCreateForOthers && _selectedPatientId == null) {
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

      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        slot.startDateTime.hour,
        slot.startDateTime.minute,
      );

      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        slot.endDateTime.hour,
        slot.endDateTime.minute,
      );

      final request = AppointmentRequest(
        doctorId: doctorId,
        branchId: branchId,
        startTime: startDateTime,
        endTime: endDateTime,
        status: 'pending',
        userId: canCreateForOthers ? _selectedPatientId : currentUser?.id,
        patientName: _fullNameController.text.trim(),
        patientPhone: _mobileController.text.trim(),
        patientEmail: _emailController.text.trim(),
        reasonForVisit: _reasonController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      debugPrint('BOOK APPOINTMENT canCreateForOthers: $canCreateForOthers');
      debugPrint('BOOK APPOINTMENT selectedPatientId: $_selectedPatientId');
      debugPrint('BOOK APPOINTMENT currentUserId: ${currentUser?.id}');
      debugPrint('BOOK APPOINTMENT payload: ${request.toJson()}');

      final result = await repo.createAppointment(request);

      ref.read(appointmentNotifierProvider.notifier).addAppointment(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment created successfully.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop(result);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: $error'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availState = ref.watch(availabilityNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = availState.selectedSlot;

    final permissionService = ref.watch(permissionServiceProvider);
    final currentUser = ref.watch(authStateProvider).user;

    final canCreateForOthers = permissionService.can(
      Perm.appointmentCreateForOthers,
    );

    debugPrint('BOOK PAGE ROLE: ${currentUser?.role}');
    debugPrint('BOOK PAGE PERMISSIONS: ${currentUser?.permissions}');
    debugPrint('BOOK PAGE CAN CREATE FOR OTHERS: $canCreateForOthers');

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Appointment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Patient Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.validateName(
                    value,
                    fieldName: 'Full name',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final requiredError = Validators.required(
                      value,
                      fieldName: 'Mobile number',
                    );
                    if (requiredError != null) return requiredError;
                    return Validators.validatePhone(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Appointment Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 12),

                _buildDoctorField(),

                const SizedBox(height: 16),

                _buildBranchField(),

                const SizedBox(height: 16),

                if (canCreateForOthers) ...[
                  PatientSearchField(
                    selectedPatientId: _selectedPatientId,
                    selectedPatientName: _selectedPatientName,
                    onPatientSelected: (PatientModel? patient) {
                      setState(() {
                        _selectedPatientId = patient?.userId;
                        _selectedPatientName = patient?.name;
                      });

                      debugPrint('Selected patient: $_selectedPatientName');
                      debugPrint(
                        'Selected patient user_id: $_selectedPatientId',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Appointment date',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Appointment Date *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: selectedDate == null
                            ? ''
                            : DateFormat('EEE, MMM dd yyyy')
                                .format(selectedDate),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  maxLength: 500,
                  validator: (value) => Validators.required(
                    value,
                    fieldName: 'Purpose of visit',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Purpose of Visit *',
                    hintText: 'e.g., Toothache, Cleaning, Check-up',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'Anything else the team should know?',
                    prefixIcon: Icon(Icons.note_add_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Appointment Time *',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                if (availState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (availState.error != null)
                  Text(
                    'Error: ${availState.error}',
                    style: const TextStyle(color: Colors.red),
                  )
                else if (availState.slots.isEmpty)
                  _infoBanner(
                    'No slots available for this date.\nTry selecting a different date.',
                  )
                else
                  TimeSlotPicker(
                    state: availState,
                    onSlotSelected: (slot) {
                      ref
                          .read(availabilityNotifierProvider.notifier)
                          .selectSlot(slot);
                    },
                  ),

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: (selectedSlot == null || _isSubmitting)
                      ? null
                      : () => _bookAppointment(selectedSlot),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Book Appointment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorField() {
    final doctorsAsync = ref.watch(doctorsListProvider);
    final selected = ref.watch(selectedDoctorProvider);

    return doctorsAsync.when(
      loading: () => const DropdownSkeleton(label: 'Loading doctors...'),
      error: (error, _) => DropdownError(
        message: 'Failed to load doctors: $error',
      ),
      data: (doctors) => DropdownButtonFormField<int>(
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Doctor *',
          prefixIcon: Icon(Icons.person_outline),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select Doctor'),
        items: doctors.map((doctor) {
          return DropdownMenuItem<int>(
            value: doctor.id,
            child: Text(
              doctor.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (id) {
          ref.read(selectedDoctorProvider.notifier).state = id;
          ref.read(availabilityNotifierProvider.notifier).clearSlots();

          _fetchSlots();
        },
      ),
    );
  }

  Widget _buildBranchField() {
    final branchesAsync = ref.watch(branchesListProvider);
    final selected = ref.watch(selectedBranchProvider);

    return branchesAsync.when(
      loading: () => const DropdownSkeleton(label: 'Loading branches...'),
      error: (error, _) => DropdownError(
        message: 'Failed to load branches: $error',
      ),
      data: (branches) => DropdownButtonFormField<int>(
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Branch *',
          prefixIcon: Icon(Icons.location_on_outlined),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select Branch'),
        items: branches.map((branch) {
          return DropdownMenuItem<int>(
            value: branch.id,
            child: Text(
              branch.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (id) {
          ref.read(selectedBranchProvider.notifier).state = id;
          ref.read(availabilityNotifierProvider.notifier).clearSlots();

          _fetchSlots();
        },
      ),
    );
  }

  Widget _infoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
