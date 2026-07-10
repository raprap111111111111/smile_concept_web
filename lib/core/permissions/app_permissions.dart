class AppPermissions {
  AppPermissions._();

  // Dashboard
  static const dashboardView = 'dashboard.view';

  // Appointments
  static const appointmentViewAny = 'appointment.viewAny';
  static const appointmentView = 'appointment.view';
  static const appointmentCreate = 'appointment.create';
  static const appointmentCreateForOthers = 'appointment.create-for-others';
  static const appointmentUpdate = 'appointment.update';
  static const appointmentDelete = 'appointment.delete';
  static const appointmentCancel = 'appointment.cancel';
  static const appointmentApprove = 'appointment.approve';
  static const appointmentUpdateStatus = 'appointment.update-status';

  // Patients
  static const patientViewAny = 'patient.viewAny';
  static const patientView = 'patient.view';
  static const patientCreate = 'patient.create';
  static const patientUpdate = 'patient.update';
  static const patientDelete = 'patient.delete';

  // Doctors
  static const doctorViewAny = 'doctor.viewAny';
  static const doctorView = 'doctor.view';
  static const doctorCreate = 'doctor.create';
  static const doctorUpdate = 'doctor.update';
  static const doctorDelete = 'doctor.delete';

  // Doctor schedules
  static const doctorScheduleViewAny = 'doctor-schedule.viewAny';
  static const doctorScheduleView = 'doctor-schedule.view';
  static const doctorScheduleCreate = 'doctor-schedule.create';
  static const doctorScheduleUpdate = 'doctor-schedule.update';
  static const doctorScheduleDelete = 'doctor-schedule.delete';

  // Services / treatments
  static const serviceViewAny = 'service.viewAny';
  static const serviceView = 'service.view';

  static const treatmentViewAny = 'treatment.viewAny';
  static const treatmentView = 'treatment.view';

  // Clinical
  static const dentalChartView = 'dental-chart.view';
  static const clinicalNoteView = 'clinical-note.view';
  static const treatmentPlanView = 'treatment-plan.view';
  static const prescriptionView = 'prescription.view';

  // Billing
  static const invoiceViewAny = 'invoice.viewAny';
  static const invoiceView = 'invoice.view';
  static const invoiceCreate = 'invoice.create';

  static const paymentViewAny = 'payment.viewAny';
  static const paymentView = 'payment.view';
  static const paymentCreate = 'payment.create';

  // Operations
  static const inventoryViewAny = 'inventory.viewAny';
  static const inventoryView = 'inventory.view';

  static const branchViewAny = 'branch.viewAny';
  static const branchView = 'branch.view';

  static const labCaseViewAny = 'lab-case.viewAny';
  static const labCaseView = 'lab-case.view';

  // System
  static const userViewAny = 'user.viewAny';
  static const userView = 'user.view';

  static const roleViewAny = 'role.viewAny';
  static const roleView = 'role.view';

  static const notificationViewAny = 'notification.viewAny';
  static const notificationView = 'notification.view';

  static const activityLogViewAny = 'activity-log.viewAny';
  static const activityLogView = 'activity-log.view';

  static const settingView = 'setting.view';
  static const settingUpdate = 'setting.update';
}