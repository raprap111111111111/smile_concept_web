// lib/presentation/pages/appointments/appointment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '/data/models/appointment/appointment_model.dart';
import '/presentation/pages/appointments/widgets/appointment_status_badge.dart';
import '/presentation/pages/appointments/appointment_form_page.dart';
import '/presentation/route/route_names.dart';

class AppointmentDetailPage extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AppointmentFormPage(
                  existingAppointment: appointment,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Header ─────────────────────────────────
            Center(
              child: Column(
                children: [
                  AppointmentStatusBadge(status: appointment.status),
                  const SizedBox(height: 4),
                  Text(
                    'Appointment #${appointment.id}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Reason for Visit (NEW) ────────────────────────
            if (appointment.reasonForVisit != null &&
                appointment.reasonForVisit!.isNotEmpty)
              _SectionCard(
                title: 'Reason for Visit',
                icon: Icons.notes_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      appointment.reasonForVisit!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            if (appointment.reasonForVisit != null) const SizedBox(height: 12),

            // ── People Card ───────────────────────────────────
            _SectionCard(
              title: 'People',
              icon: Icons.people_outline,
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Patient',
                  value: appointment.user?.name ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Doctor',
                  value: appointment.doctor?.name ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Schedule Card ─────────────────────────────────
            _SectionCard(
              title: 'Schedule',
              icon: Icons.schedule_outlined,
              children: [
                _DetailRow(
                  icon: Icons.business_outlined,
                  label: 'Branch',
                  value: appointment.branch?.name ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: dateFormat.format(appointment.startTime),
                ),
                _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Start',
                  value: timeFormat.format(appointment.startTime),
                ),
                _DetailRow(
                  icon: Icons.timer_off_outlined,
                  label: 'End',
                  value: timeFormat.format(appointment.endTime),
                ),
                _DetailRow(
                  icon: Icons.hourglass_bottom,
                  label: 'Duration',
                  value: '${appointment.duration.inMinutes} minutes',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Cancellation Reason (NEW) ─────────────────────
            if (appointment.status == AppointmentStatus.cancelled &&
                appointment.cancellationReason != null &&
                appointment.cancellationReason!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancellation Reason',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(appointment.cancellationReason!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (appointment.status == AppointmentStatus.cancelled)
              const SizedBox(height: 12),

            // ── Invoice Card (NEW) ────────────────────────────
            if (appointment.status == AppointmentStatus.completed)
              _SectionCard(
                title: 'Billing',
                icon: Icons.receipt_long_outlined,
                children: [
                  if (appointment.hasInvoice)
                    FilledButton.icon(
                      onPressed: () {
                        context.goNamed(
                          RouteNames.invoiceDetail,
                          pathParameters: {
                            'id': appointment.invoiceId!.toString(),
                          },
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Invoice'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to Create Invoice page
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Invoice'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                ],
              ),
            if (appointment.status == AppointmentStatus.completed)
              const SizedBox(height: 12),

            // ── Other Card ────────────────────────────────────
            _SectionCard(
              title: 'Other Info',
              icon: Icons.info_outline,
              children: [
                _DetailRow(
                  icon: Icons.notifications_outlined,
                  label: 'Reminder',
                  value: appointment.reminderSent ? 'Sent' : 'Not sent',
                ),
                if (appointment.createdAt != null)
                  _DetailRow(
                    icon: Icons.history,
                    label: 'Created',
                    value: DateFormat('MMM dd, yyyy').format(appointment.createdAt!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers (unchanged) ───────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}