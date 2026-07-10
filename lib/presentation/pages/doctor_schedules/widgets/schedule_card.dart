// lib/presentation/pages/doctor_schedules/widgets/schedule_card.dart

import 'package:flutter/material.dart';
import '/../data/models/doctor_schedule/doctor_schedule_model.dart';

class ScheduleCard extends StatelessWidget {
  final DoctorScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatTime(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    schedule.dayLabel,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Doctor ──────────────────────────────────────────────────
            if (schedule.doctor != null) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      schedule.doctor!.profile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  schedule.doctor!.specialty,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Branch ──────────────────────────────────────────────────
            if (schedule.branch != null)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${schedule.branch!.name} (${schedule.branch!.branchCode})',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),

            const Divider(height: 20),

            // ── Time ────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(schedule.startTime)} — ${_formatTime(schedule.endTime)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}