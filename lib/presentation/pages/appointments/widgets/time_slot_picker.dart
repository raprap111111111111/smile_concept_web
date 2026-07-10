// lib/presentation/pages/appointments/widgets/time_slot_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/appointment/availability_model.dart';
import '../../../../presentation/providers/appointment/appointment_provider.dart';

class TimeSlotPicker extends StatelessWidget {
  final AvailabilityState state;
  final ValueChanged<TimeSlot> onSlotSelected;

  const TimeSlotPicker({
    super.key,
    required this.state,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    // ── Loading ──────────────────────────────────────────────────
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────
    if (state.error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    // ── No Slots ─────────────────────────────────────────────────
    if (state.slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Select doctor, branch and date to see slots.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // ── No Available Slots ───────────────────────────────────────
    if (state.availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy, color: Colors.orange.shade400),
            const SizedBox(width: 8),
            const Text('No available slots for this day.'),
          ],
        ),
      );
    }

    final timeFormat = DateFormat('hh:mm a');

    // ── Slot Grid ────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.slots.map((slot) {
            final isSelected = state.selectedSlot?.startTime == slot.startTime;
            final isAvailable = slot.isAvailable;

            return GestureDetector(
              onTap: isAvailable ? () => onSlotSelected(slot) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isAvailable
                          ? Colors.white
                          : Colors.grey.shade100,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isAvailable
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeFormat.format(slot.startDateTime),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? Colors.black87
                            : Colors.grey.shade400,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (state.selectedSlot != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Selected: ${timeFormat.format(state.selectedSlot!.startDateTime)}'
                  ' – ${timeFormat.format(state.selectedSlot!.endDateTime)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}