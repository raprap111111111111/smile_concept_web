// lib/presentation/pages/appointments/widgets/delete_confirmation_sheet.dart

import 'package:flutter/material.dart';
import '../../../../data/models/appointment/appointment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/shared/hold_to_delete_button.dart';

class DeleteConfirmationSheet extends StatefulWidget {
  final AppointmentModel appointment;

  const DeleteConfirmationSheet({
    super.key,
    required this.appointment,
  });

  @override
  State<DeleteConfirmationSheet> createState() =>
      _DeleteConfirmationSheetState();
}

class _DeleteConfirmationSheetState extends State<DeleteConfirmationSheet> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final patientName = widget.appointment.user?.name ?? 'this patient';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Warning icon + title ─────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delete Appointment',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Description ─────────────────────────────────
              Text(
                'You are about to delete the appointment for '
                '$patientName. This action cannot be undone.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Hold-to-delete button ────────────────────────
              HoldToDeleteButton(
                label: 'Hold to delete',
                hintText: 'Press and hold for 2 seconds',
                duration: const Duration(seconds: 2),
                loading: _isDeleting,
                disabled: _isDeleting,
                onComplete: () {
                  if (!mounted) return;
                  setState(() => _isDeleting = true);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) Navigator.of(context).pop(true);
                  });
                },
              ),
              const SizedBox(height: 8),

              // ── Cancel ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}