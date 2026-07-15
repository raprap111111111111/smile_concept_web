import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smile_concept_web/data/models/appointment/appointment_request.dart';


class AppointmentFormPatient extends StatefulWidget {

  
  const AppointmentFormPatient({super.key});

  @override
  State<AppointmentFormPatient> createState() =>
      _AppointmentFormPatientState();
}

class _AppointmentFormPatientState
    extends State<AppointmentFormPatient> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _purpose;
  String? _bookingFor;

  final List<String> _purposes = [
    'Dental Check-up',
    'Teeth Cleaning',
    'Tooth Extraction',
    'Root Canal',
    'Braces Consultation',
    'Dental Filling',
    'Teeth Whitening',
    'Emergency',
    'Other',
  ];

final List<String> _bookingOptions = [
  'Myself',
  'Spouse',
  'Child',
  'Parent',
  'Other',
];

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text =
            DateFormat('MMMM d, yyyy').format(date);
      });
    }
  }

DateTime _combineDateAndTime() {
  return DateTime(
    _selectedDate!.year,
    _selectedDate!.month,
    _selectedDate!.day,
    _selectedTime!.hour,
    _selectedTime!.minute,
  );
}

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;

        final now = DateTime.now();

        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        _timeController.text =
            DateFormat('h:mm a').format(dt);
      });
    }
  }

  void _submit() {
  if (!_formKey.currentState!.validate()) return;

  final startTime = _combineDateAndTime();

  // Example: 30-minute appointment
  final endTime = startTime.add(const Duration(minutes: 30));

  final request = AppointmentRequest(
    doctorId: 1, // Replace later with selected doctor
    branchId: 1, // Replace later with selected branch
    startTime: startTime,
    endTime: endTime,

    patientName: _fullNameController.text.trim(),
    patientPhone: _mobileController.text.trim(),
    patientEmail: _emailController.text.trim(),

    reasonForVisit: _purpose,
    additionalNotes: _notesController.text.trim(),
  );

  debugPrint(request.toJson().toString());

  // Later:
  // ref.read(appointmentProvider.notifier).bookAppointment(request);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book an Appointment"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Patient Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? "Required"
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Mobile Number",
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? "Required"
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Required";
                            }

                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(v)) {
                              return "Invalid email";
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Appointment",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: const InputDecoration(
                            labelText: "Date",
                            prefixIcon:
                                Icon(Icons.calendar_today),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? "Select a date"
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          onTap: _pickTime,
                          decoration: const InputDecoration(
                            labelText: "Time",
                            prefixIcon:
                                Icon(Icons.access_time),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? "Select a time"
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _purpose,
                          decoration: const InputDecoration(
                            labelText: "Purpose of Visit",
                          ),
                          items: _purposes
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _purpose = value;
                            });
                          },
                          validator: (v) =>
                              v == null
                                  ? "Select a purpose"
                                  : null,
                        ),

                        DropdownButtonFormField<String>(
                        value: _bookingFor,
                        decoration: const InputDecoration(
                          labelText: "Booking For",
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: _bookingOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _bookingFor = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select who the appointment is for.';
                          }
                          return null;
                        },
                      ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText:
                                "Additional Notes (optional)",
                            hintText:
                                "Describe any symptoms or concerns...",
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _submit,
                            child: const Text(
                              "Book Appointment",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}