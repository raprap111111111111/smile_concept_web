// lib/presentation/constant/permission_constants.dart

class Perm {
  Perm._();

  // ── Dashboard ─────────────────────────────────────────────
  static const String dashboardView = 'dashboard.view';

  // ── Treatments ────────────────────────────────────────────
  static const String treatmentViewAny = 'treatment.viewAny';
  static const String treatmentView    = 'treatment.view';
  static const String treatmentCreate  = 'treatment.create';
  static const String treatmentUpdate  = 'treatment.update';
  static const String treatmentDelete  = 'treatment.delete';

  // ── Treatment Plans ───────────────────────────────────────
  static const String treatmentPlanViewAny = 'treatment-plan.viewAny';
  static const String treatmentPlanView    = 'treatment-plan.view';
  static const String treatmentPlanCreate  = 'treatment-plan.create';
  static const String treatmentPlanUpdate  = 'treatment-plan.update';
  static const String treatmentPlanDelete  = 'treatment-plan.delete';
  static const String treatmentPlanAccept  = 'treatment-plan.accept';
  static const String treatmentPlanReject  = 'treatment-plan.reject';
  // lib/constant/permission_constants.dart
  static const treatmentPlanSendToPatient = 'treatment-plan.send-to-patient';
  static const treatmentPlanMarkCompleted = 'treatment-plan.mark-completed';
  static const treatmentPlanReopen        = 'treatment-plan.reopen';
  static const treatmentPlanChangeStatus  = 'treatment-plan.change-status';


  // ── Prescriptions ─────────────────────────────────────────
  static const String prescriptionViewAny = 'prescription.viewAny';
  static const String prescriptionView    = 'prescription.view';
  static const String prescriptionCreate  = 'prescription.create';
  static const String prescriptionUpdate  = 'prescription.update';
  static const String prescriptionDelete  = 'prescription.delete';
  static const String prescriptionPrint   = 'prescription.print';
  static const String prescriptionSend    = 'prescription.send';

  // ── Appointments ──────────────────────────────────────────
  static const String appointmentViewAny = 'appointment.viewAny';
  static const String appointmentView    = 'appointment.view';
  static const String appointmentCreate  = 'appointment.create';
  static const String appointmentUpdate  = 'appointment.update';
  static const String appointmentDelete  = 'appointment.delete';
  static const String appointmentCancel  = 'appointment.cancel';

  // ── Patients ──────────────────────────────────────────────
  static const String patientViewAny = 'patient.viewAny';
  static const String patientView    = 'patient.view';
  static const String patientCreate  = 'patient.create';
  static const String patientUpdate  = 'patient.update';
  static const String patientDelete  = 'patient.delete';

  // ── Doctors ───────────────────────────────────────────────
  static const String doctorViewAny = 'doctor.viewAny';
  static const String doctorView    = 'doctor.view';
  static const String doctorCreate  = 'doctor.create';
  static const String doctorUpdate  = 'doctor.update';
  static const String doctorDelete  = 'doctor.delete';

  // ── Doctor Schedules ──────────────────────────────────────
  static const String doctorScheduleViewAny = 'doctor-schedule.viewAny';
  static const String doctorScheduleView    = 'doctor-schedule.view';
  static const String doctorScheduleCreate  = 'doctor-schedule.create';
  static const String doctorScheduleUpdate  = 'doctor-schedule.update';
  static const String doctorScheduleDelete  = 'doctor-schedule.delete';

  // ── Services ──────────────────────────────────────────────
  // ✅ ADD THESE — were missing entirely
  static const String serviceViewAny = 'service.viewAny';
  static const String serviceView    = 'service.view';
  static const String serviceCreate  = 'service.create';
  static const String serviceUpdate  = 'service.update';
  static const String serviceDelete  = 'service.delete';

  // ── Invoices ──────────────────────────────────────────────
  static const String invoiceViewAny = 'invoice.viewAny';
  static const String invoiceView    = 'invoice.view';
  static const String invoiceCreate  = 'invoice.create';
  static const String invoiceUpdate  = 'invoice.update';
  static const String invoiceDelete  = 'invoice.delete';

  // ── Payments ──────────────────────────────────────────────
  static const String paymentViewAny = 'payment.viewAny';
  static const String paymentView    = 'payment.view';
  static const String paymentCreate  = 'payment.create';

  // ── Users ─────────────────────────────────────────────────
  static const String userViewAny = 'user.viewAny';
  static const String userView    = 'user.view';
  static const String userCreate  = 'user.create';
  static const String userUpdate  = 'user.update';
  static const String userDelete  = 'user.delete';

  // ── Roles ─────────────────────────────────────────────────
  static const String roleViewAny = 'role.viewAny';
  static const String roleView    = 'role.view';

  // ── Branches ──────────────────────────────────────────────
  static const String branchViewAny = 'branch.viewAny';
  static const String branchView    = 'branch.view';
  static const String branchCreate  = 'branch.create';
  static const String branchUpdate  = 'branch.update';
  static const String branchDelete  = 'branch.delete';

  // ── Inventory ─────────────────────────────────────────────
  static const String inventoryViewAny = 'inventory.viewAny';
  static const String inventoryView    = 'inventory.view';
  static const String inventoryCreate  = 'inventory.create';
  static const String inventoryUpdate  = 'inventory.update';
  static const String inventoryDelete  = 'inventory.delete';

  // ── Settings ──────────────────────────────────────────────
  static const String settingView   = 'setting.view';
  static const String settingUpdate = 'setting.update';

  // ── Notifications ─────────────────────────────────────────
  static const String notificationViewAny = 'notification.viewAny';
  static const String notificationView    = 'notification.view';
  static const String notificationUpdate  = 'notification.update';

  // ── Activity Logs ─────────────────────────────────────────
  static const String activityLogViewAny = 'activity-log.viewAny';
  static const String activityLogView    = 'activity-log.view';

  // ── Lab Cases ─────────────────────────────────────────────
  static const String labCaseViewAny = 'lab-case.viewAny';
  static const String labCaseView    = 'lab-case.view';
  static const String labCaseCreate  = 'lab-case.create';
  static const String labCaseUpdate  = 'lab-case.update';
  static const String labCaseDelete  = 'lab-case.delete';

  // ── Recalls ───────────────────────────────────────────────
  static const String recallViewAny = 'recall.viewAny';
  static const String recallView    = 'recall.view';
  static const String recallCreate  = 'recall.create';

  // ── Dental Charts ─────────────────────────────────────────
  static const String dentalChartViewAny = 'dental-chart.viewAny';
  static const String dentalChartView    = 'dental-chart.view';
  static const String dentalChartCreate  = 'dental-chart.create';
  static const String dentalChartUpdate  = 'dental-chart.update';

  // ── Clinical Notes ────────────────────────────────────────
  static const String clinicalNoteViewAny = 'clinical-note.viewAny';
  static const String clinicalNoteView    = 'clinical-note.view';
  static const String clinicalNoteCreate  = 'clinical-note.create';
  static const String clinicalNoteUpdate  = 'clinical-note.update';

  // ── Medical Profile ───────────────────────────────────────
  static const String medicalProfileView   = 'medical-profile.view';
  static const String medicalProfileUpdate = 'medical-profile.update';
}