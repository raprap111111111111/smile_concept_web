// lib/presentation/pages/appointments/widgets/appointment_calendar_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/appointment/appointment_model.dart';
import 'appointment_status_badge.dart';

class AppointmentCalendarCard extends StatelessWidget {
  final AppointmentModel appointment;
  final int? currentUserId;
  final bool canViewAll;
  final bool canUpdateStatus;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onCancel;

  const AppointmentCalendarCard({
    super.key,
    required this.appointment,
    this.currentUserId,
    this.canViewAll = false,
    this.canUpdateStatus = false,
    this.onDelete,
    this.onStatusChanged,
    this.onCancel,
  });

  bool get isOwnAppointment => appointment.userId == currentUserId;

  Color _statusColor() {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatTime(DateTime d) => DateFormat('hh:mm a').format(d);

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final cancellationReason = appointment.cancellationReason;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time column ─────────────────────────────────────────
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(appointment.startTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(appointment.endTime),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── Colored side bar ────────────────────────────────────
          Container(
            width: 4,
            height: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _statusColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Card content ────────────────────────────────────────
          Expanded(
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient name + YOURS badge + Clickable Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  appointment.user?.name ?? 'Unknown Patient',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (canViewAll && isOwnAppointment) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'YOURS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ✅ CLICKABLE STATUS BADGE
                        AppointmentStatusBadge(
                          status: status,
                          canUpdate: canUpdateStatus,
                          onStatusChanged: onStatusChanged,
                          onCancel: onCancel,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Doctor
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.doctor?.name ?? 'No doctor',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Branch
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.branch?.name ?? 'No branch',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Cancellation reason
                    if (status == AppointmentStatus.cancelled &&
                        cancellationReason != null &&
                        cancellationReason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 12,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Reason: $cancellationReason',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Delete only (status changes via badge now)
                    if (onDelete != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}