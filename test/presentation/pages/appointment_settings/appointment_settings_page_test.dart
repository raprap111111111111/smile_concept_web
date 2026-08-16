import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/Users/raprap/smile_concept_web/lib/data/models/settings/appointment_settings_model.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/providers/settings/appointment_settings_provider.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/theme/app_colors.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/theme/app_dimensions.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/theme/app_text_styles.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/theme/app_theme.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/pages/doctor_schedules/widgets/days_checkbox_list.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/pages/doctor_schedules/widgets/time_picker_field.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/pages/appointment_settings/widgets/fee_field.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/pages/appointment_settings/widgets/number_stepper_field.dart';
import '/Users/raprap/smile_concept_web/lib/presentation/pages/appointment_settings/widgets/settings_section_card.dart';

// ══════════════════════════════════════════════════════════════
// PUBLIC PAGE — standalone version with Scaffold + AppBar
// Used when navigated directly via /appointment-settings
// ══════════════════════════════════════════════════════════════
class AppointmentSettingsPage extends StatelessWidget {
  const AppointmentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: const Text('Appointment Settings',
              style: AppTextStyles.titleLarge),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        body: const AppointmentSettingsView(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EMBEDDABLE VIEW — no Scaffold, no AppBar
// Used inside Settings tabs
// ══════════════════════════════════════════════════════════════
class AppointmentSettingsView extends ConsumerStatefulWidget {
  const AppointmentSettingsView({super.key});

  @override
  ConsumerState<AppointmentSettingsView> createState() =>
      _AppointmentSettingsViewState();
}

class _AppointmentSettingsViewState
    extends ConsumerState<AppointmentSettingsView> {
  final _opensController = TextEditingController();
  final _closesController = TextEditingController();
  final _lunchStartController = TextEditingController();
  final _lunchEndController = TextEditingController();

  bool _controllersSeeded = false;

  @override
  void initState() {
    super.initState();

    _opensController.addListener(() => _onTimeEdited(
        _opensController, (d, t) => d.copyWith(clinicOpensAt: t)));
    _closesController.addListener(() => _onTimeEdited(
        _closesController, (d, t) => d.copyWith(clinicClosesAt: t)));
    _lunchStartController.addListener(() => _onTimeEdited(
        _lunchStartController, (d, t) => d.copyWith(lunchBreakStart: t)));
    _lunchEndController.addListener(() => _onTimeEdited(
        _lunchEndController, (d, t) => d.copyWith(lunchBreakEnd: t)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentSettingsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _opensController.dispose();
    _closesController.dispose();
    _lunchStartController.dispose();
    _lunchEndController.dispose();
    super.dispose();
  }

  void _onTimeEdited(
    TextEditingController controller,
    AppointmentSettingsModel Function(AppointmentSettingsModel, String) apply,
  ) {
    if (!_controllersSeeded) return;
    final draft = ref.read(appointmentSettingsProvider).draft;
    if (draft == null) return;

    final text = controller.text.trim();
    if (text.length < 5) return;

    _updateDraft(apply(draft, text.substring(0, 5)));
  }

  void _updateDraft(AppointmentSettingsModel draft) {
    ref.read(appointmentSettingsProvider.notifier).updateDraft(draft);
  }

  void _seedTimeControllers(AppointmentSettingsModel model) {
    _opensController.text = '${model.clinicOpensAt}:00';
    _closesController.text = '${model.clinicClosesAt}:00';
    _lunchStartController.text = '${model.lunchBreakStart}:00';
    _lunchEndController.text = '${model.lunchBreakEnd}:00';
  }

  Future<void> _save() async {
    final saved = await ref.read(appointmentSettingsProvider.notifier).save();
    if (saved && mounted) {
      final fresh = ref.read(appointmentSettingsProvider).saved;
      if (fresh != null) _seedTimeControllers(fresh);
    }
  }

  void _discard() {
    ref.read(appointmentSettingsProvider.notifier).discardChanges();
    final saved = ref.read(appointmentSettingsProvider).saved;
    if (saved != null) _seedTimeControllers(saved);
  }

  Future<void> _reload() async {
    await ref.read(appointmentSettingsProvider.notifier).load();
    if (!mounted) return;
    final fresh = ref.read(appointmentSettingsProvider).saved;
    if (fresh != null) _seedTimeControllers(fresh);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentSettingsProvider);

    if (!_controllersSeeded && state.saved != null) {
      _seedTimeControllers(state.saved!);
      _controllersSeeded = true;
    }

    ref.listen(appointmentSettingsProvider, (previous, next) {
      if (next.justSaved && previous?.justSaved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment settings saved.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    return Theme(
      data: AppTheme.lightTheme,
      child: Column(
        children: [
          Expanded(child: _buildBody(state)),
          if (state.draft != null) _buildSaveBar(state),
        ],
      ),
    );
  }

  Widget _buildBody(AppointmentSettingsState state) {
    if (state.isLoading && state.draft == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.draft == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              onPressed: _reload,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final draft = state.draft;
    if (draft == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar with reload button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.ink),
                    tooltip: 'Reload from server',
                    onPressed: state.isLoading ? null : _reload,
                  ),
                ],
              ),
              if (state.error != null) ...[
                _ErrorBanner(
                    message: state.error!, fieldErrors: state.fieldErrors),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],
              _buildSchedulingCard(draft, state),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildCapacityCard(draft, state),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildBookingWindowCard(draft, state),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildCancellationCard(draft, state),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildRemindersCard(draft, state),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildWaitlistCard(draft, state),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section builders (unchanged from your original) ──────
  Widget _buildSchedulingCard(
      AppointmentSettingsModel d, AppointmentSettingsState state) {
    return SettingsSectionCard(
      title: 'Scheduling',
      icon: Icons.schedule_rounded,
      subtitle: 'Slot shape, clinic hours, lunch break and working days',
      children: [
        Row(
          children: [
            Expanded(
              child: NumberStepperField(
                label: 'Default Slot Duration',
                suffix: 'min',
                helper: 'Standard appointment length.',
                value: d.slotDurationMinutes,
                min: 5,
                max: 240,
                errorText: state.fieldErrors['appointment_slot_duration'],
                onChanged: (v) =>
                    _updateDraft(d.copyWith(slotDurationMinutes: v)),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: NumberStepperField(
                label: 'Buffer Between Slots',
                suffix: 'min',
                helper:
                    'Extra time between appointments for cleaning and prep.',
                value: d.bufferMinutes,
                min: 0,
                max: 120,
                errorText: state.fieldErrors['appointment_buffer_minutes'],
                onChanged: (v) => _updateDraft(d.copyWith(bufferMinutes: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: TimePickerField(
                controller: _opensController,
                label: 'Clinic Opens At',
                icon: Icons.wb_sunny_outlined,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: TimePickerField(
                controller: _closesController,
                label: 'Clinic Closes At',
                icon: Icons.nights_stay_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: TimePickerField(
                controller: _lunchStartController,
                label: 'Lunch Break Start',
                icon: Icons.lunch_dining_outlined,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: TimePickerField(
                controller: _lunchEndController,
                label: 'Lunch Break End',
                icon: Icons.restaurant_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        DaysCheckboxList(
          selectedDays: d.workingDays,
          onChanged: (days) => _updateDraft(d.copyWith(workingDays: days)),
        ),
      ],
    );
  }

  Widget _buildCapacityCard(
      AppointmentSettingsModel d, AppointmentSettingsState state) {
    return SettingsSectionCard(
      title: 'Capacity',
      icon: Icons.groups_rounded,
      subtitle: 'Daily and simultaneous appointment limits',
      children: [
        NumberStepperField(
          label: 'Max Appointments Per Dentist Per Day',
          helper: 'Limits the number of patients each dentist can see daily.',
          value: d.maxPerDentistPerDay,
          min: 1,
          max: 200,
          icon: Icons.medical_services_outlined,
          errorText: state.fieldErrors['max_appointments_per_dentist_per_day'],
          onChanged: (v) => _updateDraft(d.copyWith(maxPerDentistPerDay: v)),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        NumberStepperField(
          label: 'Max Clinic-Wide Appointments Per Day',
          helper: 'Limits the total appointments for the entire clinic.',
          value: d.maxPerDay,
          min: 1,
          max: 2000,
          icon: Icons.business_outlined,
          errorText: state.fieldErrors['max_appointments_per_day'],
          onChanged: (v) => _updateDraft(d.copyWith(maxPerDay: v)),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        NumberStepperField(
          label: 'Max Concurrent Appointments',
          helper: 'How many appointments can happen at the same time (chairs).',
          value: d.maxConcurrent,
          min: 1,
          max: 100,
          icon: Icons.chair_alt_outlined,
          errorText: state.fieldErrors['max_concurrent_appointments'],
          onChanged: (v) => _updateDraft(d.copyWith(maxConcurrent: v)),
        ),
      ],
    );
  }

  Widget _buildBookingWindowCard(
      AppointmentSettingsModel d, AppointmentSettingsState state) {
    return SettingsSectionCard(
      title: 'Booking Window',
      icon: Icons.event_available_rounded,
      subtitle: 'How far ahead (and how late) patients can book',
      children: [
        Row(
          children: [
            Expanded(
              child: NumberStepperField(
                label: 'Minimum Advance Booking',
                suffix: 'hours',
                helper: 'How many hours ahead a patient must book.',
                value: d.leadTimeHours,
                min: 0,
                max: 720,
                errorText: state.fieldErrors['booking_lead_time_hours'],
                onChanged: (v) => _updateDraft(d.copyWith(leadTimeHours: v)),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: NumberStepperField(
                label: 'Maximum Advance Booking',
                suffix: 'days',
                helper: 'How far into the future a patient can schedule.',
                value: d.maxAdvanceDays,
                min: 1,
                max: 730,
                errorText: state.fieldErrors['max_advance_booking_days'],
                onChanged: (v) => _updateDraft(d.copyWith(maxAdvanceDays: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        NumberStepperField(
          label: 'Max Future Appointments Per Patient',
          helper: 'Prevents patients from stacking up future bookings.',
          value: d.maxFuturePerPatient,
          min: 1,
          max: 50,
          icon: Icons.person_outline_rounded,
          errorText: state.fieldErrors['max_future_appointments_per_patient'],
          onChanged: (v) => _updateDraft(d.copyWith(maxFuturePerPatient: v)),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        _SettingSwitch(
          title: 'Allow Same-Day Booking',
          subtitle: 'Patients may book appointments for today.',
          value: d.allowSameDayBooking,
          onChanged: (v) => _updateDraft(d.copyWith(allowSameDayBooking: v)),
        ),
        _SettingSwitch(
          title: 'Allow Online Booking',
          subtitle: 'Master switch for patient self-service booking. '
              'Staff can always book at the front desk.',
          value: d.allowOnlineBooking,
          onChanged: (v) => _updateDraft(d.copyWith(allowOnlineBooking: v)),
        ),
      ],
    );
  }

  Widget _buildCancellationCard(
      AppointmentSettingsModel d, AppointmentSettingsState state) {
    return SettingsSectionCard(
      title: 'Cancellation & No-Show',
      icon: Icons.event_busy_rounded,
      subtitle: 'Cutoff is enforced now; fees and blocking are stored for '
          'the upcoming billing integration',
      children: [
        NumberStepperField(
          label: 'Cancellation Cutoff',
          suffix: 'hours',
          helper: 'Deadline before the appointment after which patients '
              'can no longer cancel online.',
          value: d.cancellationWindowHours,
          min: 0,
          max: 720,
          icon: Icons.timer_off_outlined,
          errorText: state.fieldErrors['cancellation_window_hours'],
          onChanged: (v) =>
              _updateDraft(d.copyWith(cancellationWindowHours: v)),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        const _NotEnforcedDivider(),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: FeeField(
                label: 'Late Cancellation Fee',
                helper:
                    'Charged for cancelling after the cutoff. Not yet enforced.',
                value: d.lateCancellationFee,
                errorText: state.fieldErrors['late_cancellation_fee'],
                onChanged: (v) =>
                    _updateDraft(d.copyWith(lateCancellationFee: v)),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: FeeField(
                label: 'No-Show Fee',
                helper:
                    'Charged when a patient does not attend. Not yet enforced.',
                value: d.noShowFee,
                errorText: state.fieldErrors['no_show_fee'],
                onChanged: (v) => _updateDraft(d.copyWith(noShowFee: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        NumberStepperField(
          label: 'No-Shows Before Patient Block',
          helper:
              'Flags or blocks a patient after this many no-shows. Not yet enforced.',
          value: d.noShowsBeforeBlock,
          min: 1,
          max: 50,
          icon: Icons.block_outlined,
          errorText: state.fieldErrors['no_shows_before_block'],
          onChanged: (v) => _updateDraft(d.copyWith(noShowsBeforeBlock: v)),
        ),
      ],
    );
  }

  Widget _buildRemindersCard(
      AppointmentSettingsModel d, AppointmentSettingsState state) {
    return SettingsSectionCard(
      title: 'Reminders & Email',
      icon: Icons.notifications_active_rounded,
      subtitle: 'Reminder timing and transactional email toggles',
      children: [
        Row(
          children: [
            Expanded(
              child: NumberStepperField(
                label: 'First Reminder',
                suffix: 'hrs before',
                helper: 'Sends the first appointment reminder.',
                value: d.firstReminderHours,
                min: 1,
                max: 720,
                errorText: state.fieldErrors['reminder_offsets'],
                onChanged: (v) =>
                    _updateDraft(d.copyWith(firstReminderHours: v)),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: NumberStepperField(
                label: 'Second Reminder',
                suffix: 'hrs before',
                helper: 'Final reminder — must be closer to the appointment '
                    'than the first.',
                value: d.secondReminderHours,
                min: 1,
                max: 720,
                errorText: state.fieldErrors['reminder_offsets'],
                onChanged: (v) =>
                    _updateDraft(d.copyWith(secondReminderHours: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        _SettingSwitch(
          title: 'Send Booking Confirmation Email',
          subtitle: 'Emails the patient after an appointment is booked. '
              'In-app notifications always stay on.',
          value: d.sendBookingConfirmationEmail,
          onChanged: (v) =>
              _updateDraft(d.copyWith(sendBookingConfirmationEmail: v)),
        ),
        _SettingSwitch(
          title: 'Send Cancellation Email',
          subtitle: 'Emails the patient when an appointment is cancelled.',
          value: d.sendCancellationEmail,
          onChanged: (v) => _updateDraft(d.copyWith(sendCancellationEmail: v)),
        ),
        _SettingSwitch(
          title: 'Send Follow-Up Email',
          subtitle: 'Aftercare / feedback email once the visit is completed.',
          value: d.sendFollowUpEmail,
          onChanged: (v) => _updateDraft(d.copyWith(sendFollowUpEmail: v)),
        ),
        if (d.sendFollowUpEmail) ...[
          const SizedBox(height: AppDimensions.paddingSmall),
          NumberStepperField(
            label: 'Follow-Up Email Delay',
            suffix: 'hours after',
            helper: 'How long after the appointment ends the follow-up goes out.',
            value: d.followUpHoursAfter,
            min: 1,
            max: 720,
            icon: Icons.mark_email_read_outlined,
            errorText: state.fieldErrors['followup_email_hours_after'],
            onChanged: (v) => _updateDraft(d.copyWith(followUpHoursAfter: v)),
          ),
        ],
      ],
    );
  }

  Widget _buildWaitlistCard(
      AppointmentSettingsModel d, AppointmentSettingsState state) {
    return SettingsSectionCard(
      title: 'Waitlist',
      icon: Icons.hourglass_top_rounded,
      subtitle: 'Stored for the upcoming waitlist feature',
      notEnforced: true,
      children: [
        _SettingSwitch(
          title: 'Enable Waitlist',
          subtitle: 'Lets patients join a waiting list when schedules are full.',
          value: d.enableWaitlist,
          onChanged: (v) => _updateDraft(d.copyWith(enableWaitlist: v)),
        ),
        if (d.enableWaitlist) ...[
          const SizedBox(height: AppDimensions.paddingSmall),
          NumberStepperField(
            label: 'Waitlist Offer Window',
            suffix: 'min',
            helper: 'How long a patient has to accept a freed-up slot.',
            value: d.waitlistOfferWindowMinutes,
            min: 5,
            max: 10080,
            icon: Icons.timer_outlined,
            errorText: state.fieldErrors['waitlist_offer_window_minutes'],
            onChanged: (v) =>
                _updateDraft(d.copyWith(waitlistOfferWindowMinutes: v)),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveBar(AppointmentSettingsState state) {
    final isDirty = state.isDirty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                isDirty ? 'You have unsaved changes.' : 'All changes saved.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDirty ? AppColors.warning : AppColors.textMuted,
                ),
              ),
            ),
            if (isDirty) ...[
              OutlinedButton(
                onPressed: state.isSaving ? null : _discard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Discard'),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
            ],
            ElevatedButton(
              onPressed: (isDirty && !state.isSaving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Text('Save Settings',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small shared pieces ────────────────────────────────────
class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

class _NotEnforcedDivider extends StatelessWidget {
  const _NotEnforcedDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'STORED, NOT YET ENFORCED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.warning.withValues(alpha: 0.9),
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Map<String, String> fieldErrors;

  const _ErrorBanner({required this.message, this.fieldErrors = const {}});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                for (final entry in fieldErrors.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}