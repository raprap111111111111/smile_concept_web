// lib/presentation/pages/appointments/widgets/appointment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/data/models/appointment/appointment_model.dart';
import '/presentation/pages/appointments/appointment_form_page.dart';
import '/presentation/pages/appointments/widgets/appointment_status_badge.dart';
import '/presentation/route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '/presentation/theme/app_theme.dart';

/// Full-detail view for a single appointment, pushed via `Navigator.push`
/// from the calendar day list and the patient agenda list alike.
///
/// Every colour here is pinned to [AppColors] and the page pins
/// [AppTheme.lightTheme] itself — main.dart still boots on `ThemeData.dark()`,
/// so an unstyled `Scaffold`/`Card` would inherit a dark surface and white
/// text and land as a mismatched dark block on this light page.
class AppointmentDetailPage extends StatelessWidget {
  final AppointmentModel appointment;
  final bool canEdit;
  final bool canCancel;
  final Future<void> Function()? onCancel;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
    this.canEdit = false,
    this.canCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  if (appointment.reasonForVisit != null &&
                      appointment.reasonForVisit!.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Reason for Visit',
                      icon: Icons.notes_outlined,
                      children: [
                        Text(
                          appointment.reasonForVisit!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                  ],
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
                  const SizedBox(height: AppDimensions.paddingMedium),
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
                        value: DateFormat('EEEE, MMMM dd, yyyy')
                            .format(appointment.startTime),
                      ),
                      _DetailRow(
                        icon: Icons.access_time_outlined,
                        label: 'Start',
                        value:
                            DateFormat('hh:mm a').format(appointment.startTime),
                      ),
                      _DetailRow(
                        icon: Icons.timer_off_outlined,
                        label: 'End',
                        value: DateFormat('hh:mm a').format(appointment.endTime),
                      ),
                      _DetailRow(
                        icon: Icons.hourglass_bottom,
                        label: 'Duration',
                        value: '${appointment.duration.inMinutes} minutes',
                      ),
                    ],
                  ),
                  if (appointment.status == AppointmentStatus.cancelled &&
                      appointment.cancellationReason != null &&
                      appointment.cancellationReason!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _ReasonBanner(reason: appointment.cancellationReason!),
                  ],
                  if (appointment.status == AppointmentStatus.completed) ...[
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _SectionCard(
                      title: 'Billing',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        if (appointment.hasInvoice)
                          FilledButton.icon(
                            onPressed: () => context.goNamed(
                              RouteNames.invoiceDetail,
                              pathParameters: {
                                'id': appointment.invoiceId!.toString(),
                              },
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadius,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('View Invoice'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadius,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Invoice'),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingMedium),
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
                          value: DateFormat('MMM dd, yyyy')
                              .format(appointment.createdAt!),
                        ),
                    ],
                  ),
                  if (canCancel && onCancel != null) ...[
                    const SizedBox(height: AppDimensions.paddingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await onCancel!();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadius,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Appointment'),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: AppColors.textOnPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Appointment Details', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AppointmentStatusBadge(status: appointment.status),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text('#${appointment.id}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AppointmentFormPage(
                    existingAppointment: appointment,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primaryDark,
              ),
            ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────
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
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppDimensions.paddingXS),
              Text(title, style: AppTextStyles.titleSmall),
            ],
          ),
          const Divider(
            height: AppDimensions.paddingLarge,
            color: AppColors.border,
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: AppDimensions.paddingSmall),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  final String reason;

  const _ReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledSoft,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: AppColors.statusCancelledInk.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.statusCancelledInk,
          ),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.statusCancelledInk,
                ),
                children: [
                  const TextSpan(
                    text: 'Cancellation reason: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
