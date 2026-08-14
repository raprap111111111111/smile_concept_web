import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Typed mirror of GET/PUT /appointment-settings.
///
/// Field names match the backend settings keys one-to-one so a 422 error bag
/// keyed by setting key can be mapped straight onto form fields.
/// Hand-written JSON — this repo does not run build_runner.
@immutable
class AppointmentSettingsModel {
  // Scheduling
  final int slotDurationMinutes;
  final int bufferMinutes;
  final String clinicOpensAt; // "HH:mm"
  final String clinicClosesAt;
  final String lunchBreakStart;
  final String lunchBreakEnd;
  final Set<int> workingDays; // Sunday = 0, matches kDaysOfWeek

  // Capacity
  final int maxPerDentistPerDay;
  final int maxPerDay;
  final int maxConcurrent;

  // Booking window
  final int leadTimeHours;
  final int maxAdvanceDays;
  final bool allowSameDayBooking;
  final int maxFuturePerPatient;
  final bool allowOnlineBooking;

  // Cancellation & no-show
  final int cancellationWindowHours;
  final double lateCancellationFee;
  final double noShowFee;
  final int noShowsBeforeBlock;

  // Reminders & email
  final int firstReminderHours;
  final int secondReminderHours;
  final bool sendBookingConfirmationEmail;
  final bool sendCancellationEmail;
  final bool sendFollowUpEmail;
  final int followUpHoursAfter;

  // Waitlist
  final bool enableWaitlist;
  final int waitlistOfferWindowMinutes;

  const AppointmentSettingsModel({
    required this.slotDurationMinutes,
    required this.bufferMinutes,
    required this.clinicOpensAt,
    required this.clinicClosesAt,
    required this.lunchBreakStart,
    required this.lunchBreakEnd,
    required this.workingDays,
    required this.maxPerDentistPerDay,
    required this.maxPerDay,
    required this.maxConcurrent,
    required this.leadTimeHours,
    required this.maxAdvanceDays,
    required this.allowSameDayBooking,
    required this.maxFuturePerPatient,
    required this.allowOnlineBooking,
    required this.cancellationWindowHours,
    required this.lateCancellationFee,
    required this.noShowFee,
    required this.noShowsBeforeBlock,
    required this.firstReminderHours,
    required this.secondReminderHours,
    required this.sendBookingConfirmationEmail,
    required this.sendCancellationEmail,
    required this.sendFollowUpEmail,
    required this.followUpHoursAfter,
    required this.enableWaitlist,
    required this.waitlistOfferWindowMinutes,
  });

  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic v, double fallback) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  /// Backend sends "HH:mm"; tolerate "HH:mm:ss" from other endpoints.
  static String _asTime(dynamic v, String fallback) {
    if (v is! String || v.trim().isEmpty) return fallback;
    final parts = v.trim().split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  factory AppointmentSettingsModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['working_days'];
    final days = rawDays is List
        ? rawDays.map((d) => _asInt(d, -1)).where((d) => d >= 0 && d <= 6).toSet()
        : {1, 2, 3, 4, 5, 6};

    final rawOffsets = json['reminder_offsets'];
    final offsets = rawOffsets is List
        ? rawOffsets.map((h) => _asInt(h, 0)).where((h) => h > 0).toList()
        : const [24, 1];

    return AppointmentSettingsModel(
      slotDurationMinutes: _asInt(json['appointment_slot_duration'], 30),
      bufferMinutes: _asInt(json['appointment_buffer_minutes'], 0),
      clinicOpensAt: _asTime(json['clinic_opens_at'], '09:00'),
      clinicClosesAt: _asTime(json['clinic_closes_at'], '18:00'),
      lunchBreakStart: _asTime(json['lunch_break_start'], '12:00'),
      lunchBreakEnd: _asTime(json['lunch_break_end'], '13:00'),
      workingDays: days,
      maxPerDentistPerDay: _asInt(json['max_appointments_per_dentist_per_day'], 12),
      maxPerDay: _asInt(json['max_appointments_per_day'], 60),
      maxConcurrent: _asInt(json['max_concurrent_appointments'], 3),
      leadTimeHours: _asInt(json['booking_lead_time_hours'], 2),
      maxAdvanceDays: _asInt(json['max_advance_booking_days'], 90),
      allowSameDayBooking: _asBool(json['allow_same_day_booking'], true),
      maxFuturePerPatient: _asInt(json['max_future_appointments_per_patient'], 3),
      allowOnlineBooking: _asBool(json['allow_online_booking'], true),
      cancellationWindowHours: _asInt(json['cancellation_window_hours'], 24),
      lateCancellationFee: _asDouble(json['late_cancellation_fee'], 0),
      noShowFee: _asDouble(json['no_show_fee'], 0),
      noShowsBeforeBlock: _asInt(json['no_shows_before_block'], 3),
      firstReminderHours: offsets.isNotEmpty ? offsets[0] : 24,
      secondReminderHours: offsets.length > 1 ? offsets[1] : 1,
      sendBookingConfirmationEmail: _asBool(json['send_booking_confirmation_email'], true),
      sendCancellationEmail: _asBool(json['send_cancellation_email'], true),
      sendFollowUpEmail: _asBool(json['send_followup_email'], false),
      followUpHoursAfter: _asInt(json['followup_email_hours_after'], 24),
      enableWaitlist: _asBool(json['enable_waitlist'], false),
      waitlistOfferWindowMinutes: _asInt(json['waitlist_offer_window_minutes'], 120),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_slot_duration': slotDurationMinutes,
      'appointment_buffer_minutes': bufferMinutes,
      'clinic_opens_at': clinicOpensAt,
      'clinic_closes_at': clinicClosesAt,
      'lunch_break_start': lunchBreakStart,
      'lunch_break_end': lunchBreakEnd,
      'working_days': workingDays.toList()..sort(),
      'max_appointments_per_dentist_per_day': maxPerDentistPerDay,
      'max_appointments_per_day': maxPerDay,
      'max_concurrent_appointments': maxConcurrent,
      'booking_lead_time_hours': leadTimeHours,
      'max_advance_booking_days': maxAdvanceDays,
      'allow_same_day_booking': allowSameDayBooking,
      'max_future_appointments_per_patient': maxFuturePerPatient,
      'allow_online_booking': allowOnlineBooking,
      'cancellation_window_hours': cancellationWindowHours,
      'late_cancellation_fee': lateCancellationFee,
      'no_show_fee': noShowFee,
      'no_shows_before_block': noShowsBeforeBlock,
      'reminder_offsets': [firstReminderHours, secondReminderHours],
      'send_booking_confirmation_email': sendBookingConfirmationEmail,
      'send_cancellation_email': sendCancellationEmail,
      'send_followup_email': sendFollowUpEmail,
      'followup_email_hours_after': followUpHoursAfter,
      'enable_waitlist': enableWaitlist,
      'waitlist_offer_window_minutes': waitlistOfferWindowMinutes,
    };
  }

  AppointmentSettingsModel copyWith({
    int? slotDurationMinutes,
    int? bufferMinutes,
    String? clinicOpensAt,
    String? clinicClosesAt,
    String? lunchBreakStart,
    String? lunchBreakEnd,
    Set<int>? workingDays,
    int? maxPerDentistPerDay,
    int? maxPerDay,
    int? maxConcurrent,
    int? leadTimeHours,
    int? maxAdvanceDays,
    bool? allowSameDayBooking,
    int? maxFuturePerPatient,
    bool? allowOnlineBooking,
    int? cancellationWindowHours,
    double? lateCancellationFee,
    double? noShowFee,
    int? noShowsBeforeBlock,
    int? firstReminderHours,
    int? secondReminderHours,
    bool? sendBookingConfirmationEmail,
    bool? sendCancellationEmail,
    bool? sendFollowUpEmail,
    int? followUpHoursAfter,
    bool? enableWaitlist,
    int? waitlistOfferWindowMinutes,
  }) {
    return AppointmentSettingsModel(
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      clinicOpensAt: clinicOpensAt ?? this.clinicOpensAt,
      clinicClosesAt: clinicClosesAt ?? this.clinicClosesAt,
      lunchBreakStart: lunchBreakStart ?? this.lunchBreakStart,
      lunchBreakEnd: lunchBreakEnd ?? this.lunchBreakEnd,
      workingDays: workingDays ?? this.workingDays,
      maxPerDentistPerDay: maxPerDentistPerDay ?? this.maxPerDentistPerDay,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      leadTimeHours: leadTimeHours ?? this.leadTimeHours,
      maxAdvanceDays: maxAdvanceDays ?? this.maxAdvanceDays,
      allowSameDayBooking: allowSameDayBooking ?? this.allowSameDayBooking,
      maxFuturePerPatient: maxFuturePerPatient ?? this.maxFuturePerPatient,
      allowOnlineBooking: allowOnlineBooking ?? this.allowOnlineBooking,
      cancellationWindowHours: cancellationWindowHours ?? this.cancellationWindowHours,
      lateCancellationFee: lateCancellationFee ?? this.lateCancellationFee,
      noShowFee: noShowFee ?? this.noShowFee,
      noShowsBeforeBlock: noShowsBeforeBlock ?? this.noShowsBeforeBlock,
      firstReminderHours: firstReminderHours ?? this.firstReminderHours,
      secondReminderHours: secondReminderHours ?? this.secondReminderHours,
      sendBookingConfirmationEmail: sendBookingConfirmationEmail ?? this.sendBookingConfirmationEmail,
      sendCancellationEmail: sendCancellationEmail ?? this.sendCancellationEmail,
      sendFollowUpEmail: sendFollowUpEmail ?? this.sendFollowUpEmail,
      followUpHoursAfter: followUpHoursAfter ?? this.followUpHoursAfter,
      enableWaitlist: enableWaitlist ?? this.enableWaitlist,
      waitlistOfferWindowMinutes: waitlistOfferWindowMinutes ?? this.waitlistOfferWindowMinutes,
    );
  }

  /// Equality drives the Save button's dirty flag. DeepCollectionEquality
  /// because toJson() nests lists (working_days, reminder_offsets), which
  /// mapEquals would compare by identity.
  @override
  bool operator ==(Object other) {
    return other is AppointmentSettingsModel &&
        const DeepCollectionEquality().equals(toJson(), other.toJson());
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}
