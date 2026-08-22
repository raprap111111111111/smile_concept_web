// lib/presentation/pages/appointments/widgets/patient_slot_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment/availability_model.dart';
import '../../../providers/appointment/appointment_provider.dart'; // ✅ FIXED: Added missing provider import
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import 'patient_form_layout.dart';

String getSlotErrorMessage(String raw) {
  final message = raw.replaceAll('Exception: ', '').replaceAll('Forbidden: ', '').replaceAll('Unauthorized: ', '');
  final lowered = raw.toLowerCase();
  if (lowered.contains('forbidden') || lowered.contains('unauthorized')) {
    return 'Your account can\'t view open times. Please contact the clinic.';
  }
  return 'Could not load times. $message';
}

class SlotPickerGrid extends StatelessWidget {
  final AvailabilityState state;
  final bool hasPrerequisites;
  final TextStyle textStyle;
  final ValueChanged<TimeSlot> onSlotSelected;

  const SlotPickerGrid({
    super.key,
    required this.state,
    required this.hasPrerequisites,
    required this.textStyle,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const FieldPlaceholder(label: 'Finding open times...');
    if (state.error != null) return FieldPlaceholder(label: getSlotErrorMessage(state.error!), isError: true);
    if (!hasPrerequisites) return const SlotNotice(icon: Icons.schedule_outlined, message: 'Choose a branch, dentist and date to see open times.');
    if (state.slots.isEmpty) return const SlotNotice(icon: Icons.event_busy_outlined, message: 'This dentist has no hours on this day. Try another date.');
    if (state.availableSlots.isEmpty) return const SlotNotice(icon: Icons.event_busy_outlined, message: 'Fully booked on this day. Try another date or dentist.');

    final timeFormat = DateFormat('h:mm a');

    return Wrap(
      spacing: AppDimensions.paddingSmall,
      runSpacing: AppDimensions.paddingSmall,
      children: state.slots.map((slot) {
        final isSelected = state.selectedSlot?.startTime == slot.startTime;
        return SlotChip(
          label: timeFormat.format(slot.startDateTime),
          isSelected: isSelected,
          isAvailable: slot.isAvailable,
          textStyle: textStyle,
          onTap: slot.isAvailable ? () => onSlotSelected(slot) : null,
        );
      }).toList(),
    );
  }
}

class SlotChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAvailable;
  final TextStyle textStyle;
  final VoidCallback? onTap;

  const SlotChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isAvailable,
    required this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isSelected ? AppColors.primary : (isAvailable ? AppColors.background : AppColors.surface);
    final border = isSelected ? AppColors.primary : (isAvailable ? AppColors.border : AppColors.line);
    final foreground = isSelected ? AppColors.textOnPrimary : (isAvailable ? AppColors.ink : AppColors.textTertiary);

    return Semantics(
      button: isAvailable,
      selected: isSelected,
      label: isAvailable ? label : '$label, unavailable',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        mouseCursor: isAvailable ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium, vertical: AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Text(
            label,
            style: textStyle.copyWith(
              color: foreground,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              decoration: isAvailable ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

class SlotNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const SlotNotice({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconSizeSmall, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class ScheduleSummary extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const ScheduleSummary({super.key, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined, size: AppDimensions.iconSizeMedium, color: AppColors.primaryDark),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Text(
              '${DateFormat('EEEE, MMMM d').format(start)} at '
              '${DateFormat('h:mm a').format(start)} – '
              '${DateFormat('h:mm a').format(end)} '
              '· ${end.difference(start).inMinutes} minutes',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}