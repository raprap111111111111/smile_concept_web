// lib/presentation/constant/permission_constants.dart
class Perm {
  Perm._(); // prevent instantiation

  // ── Dashboard ─────────────────────────────────────────────────────────
  static const String dashboardView = 'dashboard.view';

  // ── Settings ──────────────────────────────────────────────────────────
  static const String settingView = 'setting.view';
  static const String settingUpdate = 'setting.update';

  // ── Notifications ─────────────────────────────────────────────────────
  static const String notificationViewAny = 'notification.viewAny';
  static const String notificationView = 'notification.view';
  static const String notificationUpdate = 'notification.update';

  // ── Activity Logs ─────────────────────────────────────────────────────
  static const String activityLogViewAny = 'activity-log.viewAny';
  static const String activityLogView = 'activity-log.view';

  // ── Appointments ──────────────────────────────────────────────────────
  static const String appointmentViewAny = 'appointment.viewAny';
  static const String appointmentView = 'appointment.view';
  static const String appointmentCreate = 'appointment.create';
  static const String appointmentUpdate = 'appointment.update';
  static const String appointmentDelete = 'appointment.delete';
  static const String appointmentCancel = 'appointment.cancel';
  static const String appointmentReschedule = 'appointment.reschedule';

  // ── Patients ──────────────────────────────────────────────────────────
  static const String patientViewAny = 'patient.viewAny';
  static const String patientView = 'patient.view';
  static const String patientCreate = 'patient.create';
  static const String patientUpdate = 'patient.update';
  static const String patientDelete = 'patient.delete';

  // ── Medical Profile ───────────────────────────────────────────────────
  static const String medicalProfileView = 'medical-profile.view';
  static const String medicalProfileUpdate = 'medical-profile.update';

  // ── Doctors ───────────────────────────────────────────────────────────
  static const String doctorViewAny = 'doctor.viewAny';
  static const String doctorView = 'doctor.view';

  // ── Doctor Schedules ──────────────────────────────────────────────────
  static const String doctorScheduleViewAny = 'doctor-schedule.viewAny';
  static const String doctorScheduleView = 'doctor-schedule.view';

  // ── Services ──────────────────────────────────────────────────────────
  static const String serviceViewAny = 'service.viewAny';
  static const String serviceView = 'service.view';

  // ── Clinical ──────────────────────────────────────────────────────────
  static const String clinicalNoteViewAny = 'clinical-note.viewAny';
  static const String clinicalNoteView = 'clinical-note.view';
  static const String dentalChartViewAny = 'dental-chart.viewAny';
  static const String dentalChartView = 'dental-chart.view';

  // ── Treatments ────────────────────────────────────────────────────────
  static const String treatmentViewAny = 'treatment.viewAny';
  static const String treatmentView = 'treatment.view';
  static const String treatmentPlanViewAny = 'treatment-plan.viewAny';
  static const String treatmentPlanView = 'treatment-plan.view';
  static const String treatmentPlanAccept = 'treatment-plan.accept';
  static const String treatmentPlanReject = 'treatment-plan.reject';


  // ── Prescriptions ─────────────────────────────────
  static const String prescriptionViewAny = 'prescription.viewAny';
  static const String prescriptionView    = 'prescription.view';
  static const String prescriptionCreate  = 'prescription.create';
  static const String prescriptionUpdate  = 'prescription.update';
  static const String prescriptionDelete  = 'prescription.delete';
  static const String prescriptionPrint   = 'prescription.print';
  static const String prescriptionSend    = 'prescription.send';



  // ── Invoices ──────────────────────────────────────────────────────────
  static const String invoiceViewAny = 'invoice.viewAny';
  static const String invoiceView = 'invoice.view';
  static const String invoiceCreate = 'invoice.create';

  // ── Payments ──────────────────────────────────────────────────────────
  static const String paymentViewAny = 'payment.viewAny';
  static const String paymentView = 'payment.view';
  static const String paymentCreate = 'payment.create';

  // ── Inventory ─────────────────────────────────────────────────────────
  static const String inventoryViewAny = 'inventory.viewAny';
  static const String inventoryView = 'inventory.view';

  // ── Branches ──────────────────────────────────────────────────────────
  static const String branchViewAny = 'branch.viewAny';
  static const String branchView = 'branch.view';

  // ── Lab Cases ─────────────────────────────────────────────────────────
  static const String labCaseViewAny = 'lab-case.viewAny';
  static const String labCaseView = 'lab-case.view';

  // ── Users ─────────────────────────────────────────────────────────────
  static const String userViewAny = 'user.viewAny';
  static const String userView = 'user.view';
  static const String userCreate = 'user.create';
  static const String userUpdate = 'user.update';
  static const String userDelete = 'user.delete';

  // ── Roles ─────────────────────────────────────────────────────────────
  static const String roleViewAny = 'role.viewAny';
  static const String roleView = 'role.view';

  // ── FAQ / Gallery (public content) ────────────────────────────────────
  static const String faqView = 'faq.view';
  static const String faqViewAny = 'faq.viewAny';
  static const String galleryView = 'gallery.view';
  static const String galleryViewAny = 'gallery.viewAny';
}
