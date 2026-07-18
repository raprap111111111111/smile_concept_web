// lib/presentation/constant/permission_constants.dart

/// All permission constants used in the app.
/// Must match backend permission names exactly.
class Perm {
  Perm._();

  // ═══════════════════════════════════════════════════════════
  // 📊 DASHBOARD & SETTINGS
  // ═══════════════════════════════════════════════════════════
  static const String dashboardView = 'dashboard.view';

  static const String settingView = 'setting.view';
  static const String settingUpdate = 'setting.update';

  static const String activityLogViewAny = 'activity-log.viewAny';
  static const String activityLogView = 'activity-log.view';
  static const String activityLogExport = 'activity-log.export';

  static const String notificationViewAny = 'notification.viewAny';
  static const String notificationView = 'notification.view';
  static const String notificationCreate = 'notification.create';
  static const String notificationUpdate = 'notification.update';
  static const String notificationDelete = 'notification.delete';

  // ═══════════════════════════════════════════════════════════
  // 🔐 SECURITY & IDENTITY
  // ═══════════════════════════════════════════════════════════
  static const String userViewAny = 'user.viewAny';
  static const String userView = 'user.view';
  static const String userCreate = 'user.create';
  static const String userUpdate = 'user.update';
  static const String userDelete = 'user.delete';
  static const String userRestore = 'user.restore';
  static const String userForceDelete = 'user.forceDelete';
  static const String userImpersonate = 'user.impersonate';
  static const String userResetPassword = 'user.reset-password';

  static const String roleViewAny = 'role.viewAny';
  static const String roleView = 'role.view';
  static const String roleCreate = 'role.create';
  static const String roleUpdate = 'role.update';
  static const String roleDelete = 'role.delete';
  static const String roleRestore = 'role.restore';
  static const String roleForceDelete = 'role.forceDelete';

  static const String permissionViewAny = 'permission.viewAny';
  static const String permissionView = 'permission.view';
  static const String permissionCreate = 'permission.create';
  static const String permissionUpdate = 'permission.update';
  static const String permissionDelete = 'permission.delete';
  static const String permissionRestore = 'permission.restore';
  static const String permissionForceDelete = 'permission.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 🏢 BRANCHES
  // ═══════════════════════════════════════════════════════════
  static const String branchViewAny = 'branch.viewAny';
  static const String branchView = 'branch.view';
  static const String branchCreate = 'branch.create';
  static const String branchUpdate = 'branch.update';
  static const String branchDelete = 'branch.delete';
  static const String branchRestore = 'branch.restore';
  static const String branchForceDelete = 'branch.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 🩺 DOCTORS & SCHEDULES
  // ═══════════════════════════════════════════════════════════
  static const String doctorViewAny = 'doctor.viewAny';
  static const String doctorView = 'doctor.view';
  static const String doctorCreate = 'doctor.create';
  static const String doctorUpdate = 'doctor.update';
  static const String doctorDelete = 'doctor.delete';
  static const String doctorRestore = 'doctor.restore';
  static const String doctorForceDelete = 'doctor.forceDelete';

  static const String doctorScheduleViewAny = 'doctor-schedule.viewAny';
  static const String doctorScheduleView = 'doctor-schedule.view';
  static const String doctorScheduleCreate = 'doctor-schedule.create';
  static const String doctorScheduleUpdate = 'doctor-schedule.update';
  static const String doctorScheduleDelete = 'doctor-schedule.delete';
  static const String doctorScheduleRestore = 'doctor-schedule.restore';
  static const String doctorScheduleForceDelete = 'doctor-schedule.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 📅 APPOINTMENTS
  // ═══════════════════════════════════════════════════════════
  static const String appointmentViewAny = 'appointment.viewAny';
  static const String appointmentView = 'appointment.view';
  static const String appointmentCreate = 'appointment.create';
  static const String appointmentUpdate = 'appointment.update';
  static const String appointmentDelete = 'appointment.delete';
  static const String appointmentRestore = 'appointment.restore';
  static const String appointmentForceDelete = 'appointment.forceDelete';
  static const String appointmentApprove = 'appointment.approve';
  static const String appointmentReject = 'appointment.reject';
  static const String appointmentCancel = 'appointment.cancel';
  static const String appointmentReschedule = 'appointment.reschedule';
  static const String appointmentCheckIn = 'appointment.check-in';
  static const String appointmentCheckOut = 'appointment.check-out';
  static const String appointmentNoShow = 'appointment.no-show';
  static const String appointmentComplete = 'appointment.complete';
  static const String appointmentUpdateStatus = 'appointment.update-status';
  static const String appointmentCreateForOthers =
      'appointment.create-for-others';

  // ═══════════════════════════════════════════════════════════
  // 🔔 RECALLS
  // ═══════════════════════════════════════════════════════════
  static const String recallViewAny = 'recall.viewAny';
  static const String recallView = 'recall.view';
  static const String recallCreate = 'recall.create';
  static const String recallUpdate = 'recall.update';
  static const String recallDelete = 'recall.delete';
  static const String recallRestore = 'recall.restore';
  static const String recallForceDelete = 'recall.forceDelete';
  static const String recallSendReminder = 'recall.send-reminder';
  static const String recallMarkCompleted = 'recall.mark-completed';

  // ═══════════════════════════════════════════════════════════
  // 🧑 PATIENTS
  // ═══════════════════════════════════════════════════════════
  static const String patientViewAny = 'patient.viewAny';
  static const String patientView = 'patient.view';
  static const String patientCreate = 'patient.create';
  static const String patientUpdate = 'patient.update';
  static const String patientDelete = 'patient.delete';
  static const String patientRestore = 'patient.restore';
  static const String patientForceDelete = 'patient.forceDelete';
  static const String patientExport = 'patient.export';
  static const String patientMerge = 'patient.merge';
  static const String patientTransferBranch = 'patient.transfer-branch';

  // ═══════════════════════════════════════════════════════════
  // 🏥 MEDICAL PROFILE / ITEM / ALERT
  // ═══════════════════════════════════════════════════════════
  static const String medicalProfileViewAny = 'medical-profile.viewAny';
  static const String medicalProfileView = 'medical-profile.view';
  static const String medicalProfileCreate = 'medical-profile.create';
  static const String medicalProfileUpdate = 'medical-profile.update';
  static const String medicalProfileDelete = 'medical-profile.delete';
  static const String medicalProfileRestore = 'medical-profile.restore';
  static const String medicalProfileForceDelete = 'medical-profile.forceDelete';

  static const String medicalItemViewAny = 'medical-item.viewAny';
  static const String medicalItemView = 'medical-item.view';
  static const String medicalItemCreate = 'medical-item.create';
  static const String medicalItemUpdate = 'medical-item.update';
  static const String medicalItemDelete = 'medical-item.delete';
  static const String medicalItemRestore = 'medical-item.restore';
  static const String medicalItemForceDelete = 'medical-item.forceDelete';

  static const String medicalAlertViewAny = 'medical-alert.viewAny';
  static const String medicalAlertView = 'medical-alert.view';
  static const String medicalAlertCreate = 'medical-alert.create';
  static const String medicalAlertUpdate = 'medical-alert.update';
  static const String medicalAlertDelete = 'medical-alert.delete';
  static const String medicalAlertRestore = 'medical-alert.restore';
  static const String medicalAlertForceDelete = 'medical-alert.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 🦷 CLINICAL — DENTAL CHART / NOTES / TREATMENTS
  // ═══════════════════════════════════════════════════════════
  static const String dentalChartViewAny = 'dental-chart.viewAny';
  static const String dentalChartView = 'dental-chart.view';
  static const String dentalChartCreate = 'dental-chart.create';
  static const String dentalChartUpdate = 'dental-chart.update';
  static const String dentalChartDelete = 'dental-chart.delete';
  static const String dentalChartRestore = 'dental-chart.restore';
  static const String dentalChartForceDelete = 'dental-chart.forceDelete';

  static const String clinicalNoteViewAny = 'clinical-note.viewAny';
  static const String clinicalNoteView = 'clinical-note.view';
  static const String clinicalNoteCreate = 'clinical-note.create';
  static const String clinicalNoteUpdate = 'clinical-note.update';
  static const String clinicalNoteDelete = 'clinical-note.delete';
  static const String clinicalNoteRestore = 'clinical-note.restore';
  static const String clinicalNoteForceDelete = 'clinical-note.forceDelete';
  static const String clinicalNoteFinalize = 'clinical-note.finalize';
  static const String clinicalNoteAmend = 'clinical-note.amend';

  static const String treatmentViewAny = 'treatment.viewAny';
  static const String treatmentView = 'treatment.view';
  static const String treatmentCreate = 'treatment.create';
  static const String treatmentUpdate = 'treatment.update';
  static const String treatmentDelete = 'treatment.delete';
  static const String treatmentRestore = 'treatment.restore';
  static const String treatmentForceDelete = 'treatment.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 📋 TREATMENT PLANS
  // ═══════════════════════════════════════════════════════════
  static const String treatmentPlanViewAny = 'treatment-plan.viewAny';
  static const String treatmentPlanView = 'treatment-plan.view';
  static const String treatmentPlanCreate = 'treatment-plan.create';
  static const String treatmentPlanUpdate = 'treatment-plan.update';
  static const String treatmentPlanDelete = 'treatment-plan.delete';
  static const String treatmentPlanRestore = 'treatment-plan.restore';
  static const String treatmentPlanForceDelete = 'treatment-plan.forceDelete';
  static const String treatmentPlanAccept = 'treatment-plan.accept';
  static const String treatmentPlanReject = 'treatment-plan.reject';
  static const String treatmentPlanSendToPatient =
      'treatment-plan.send-to-patient';
  static const String treatmentPlanMarkCompleted =
      'treatment-plan.mark-completed';
  static const String treatmentPlanReopen = 'treatment-plan.reopen';
  static const String treatmentPlanChangeStatus =
      'treatment-plan.change-status';

  // ═══════════════════════════════════════════════════════════
  // 💊 PRESCRIPTIONS
  // ═══════════════════════════════════════════════════════════
  static const String prescriptionViewAny = 'prescription.viewAny';
  static const String prescriptionView = 'prescription.view';
  static const String prescriptionCreate = 'prescription.create';
  static const String prescriptionUpdate = 'prescription.update';
  static const String prescriptionDelete = 'prescription.delete';
  static const String prescriptionRestore = 'prescription.restore';
  static const String prescriptionForceDelete = 'prescription.forceDelete';
  static const String prescriptionPrint = 'prescription.print';
  static const String prescriptionSend = 'prescription.send';

  // ═══════════════════════════════════════════════════════════
  // 📎 ATTACHMENTS
  // ═══════════════════════════════════════════════════════════
  static const String attachmentViewAny = 'attachment.viewAny';
  static const String attachmentView = 'attachment.view';
  static const String attachmentCreate = 'attachment.create';
  static const String attachmentUpdate = 'attachment.update';
  static const String attachmentDelete = 'attachment.delete';
  static const String attachmentRestore = 'attachment.restore';
  static const String attachmentForceDelete = 'attachment.forceDelete';
  static const String attachmentDownload = 'attachment.download';
  static const String attachmentUpload = 'attachment.upload';

  // ═══════════════════════════════════════════════════════════
  // 📄 CONSENT FORMS
  // ═══════════════════════════════════════════════════════════
  static const String consentFormViewAny = 'consent-form.viewAny';
  static const String consentFormView = 'consent-form.view';
  static const String consentFormCreate = 'consent-form.create';
  static const String consentFormUpdate = 'consent-form.update';
  static const String consentFormDelete = 'consent-form.delete';
  static const String consentFormRestore = 'consent-form.restore';
  static const String consentFormForceDelete = 'consent-form.forceDelete';
  static const String consentFormSend = 'consent-form.send';
  static const String consentFormSign = 'consent-form.sign';
  static const String consentFormVoid = 'consent-form.void';
  static const String consentFormPrint = 'consent-form.print';

  // ═══════════════════════════════════════════════════════════
  // 🔬 LAB & LAB CASES
  // ═══════════════════════════════════════════════════════════
  static const String labViewAny = 'lab.viewAny';
  static const String labView = 'lab.view';
  static const String labCreate = 'lab.create';
  static const String labUpdate = 'lab.update';
  static const String labDelete = 'lab.delete';
  static const String labRestore = 'lab.restore';
  static const String labForceDelete = 'lab.forceDelete';

  static const String labCaseViewAny = 'lab-case.viewAny';
  static const String labCaseView = 'lab-case.view';
  static const String labCaseCreate = 'lab-case.create';
  static const String labCaseUpdate = 'lab-case.update';
  static const String labCaseDelete = 'lab-case.delete';
  static const String labCaseRestore = 'lab-case.restore';
  static const String labCaseForceDelete = 'lab-case.forceDelete';
  static const String labCaseSend = 'lab-case.send';
  static const String labCaseReceive = 'lab-case.receive';
  static const String labCaseQualityCheck = 'lab-case.quality-check';
  static const String labCaseInstall = 'lab-case.install';
  static const String labCaseReturn = 'lab-case.return';

  // ═══════════════════════════════════════════════════════════
  // 💰 FINANCIAL — INVOICES / PAYMENTS / DISCOUNTS / TAX
  // ═══════════════════════════════════════════════════════════
  static const String invoiceViewAny = 'invoice.viewAny';
  static const String invoiceView = 'invoice.view';
  static const String invoiceCreate = 'invoice.create';
  static const String invoiceUpdate = 'invoice.update';
  static const String invoiceDelete = 'invoice.delete';
  static const String invoiceRestore = 'invoice.restore';
  static const String invoiceForceDelete = 'invoice.forceDelete';
  static const String invoiceSend = 'invoice.send';
  static const String invoiceMarkPaid = 'invoice.mark-paid';
  static const String invoiceVoid = 'invoice.void';
  static const String invoicePrint = 'invoice.print';
  static const String invoiceExport = 'invoice.export';
  static const String invoiceRefund = 'invoice.refund';

  static const String paymentViewAny = 'payment.viewAny';
  static const String paymentView = 'payment.view';
  static const String paymentCreate = 'payment.create';
  static const String paymentUpdate = 'payment.update';
  static const String paymentDelete = 'payment.delete';
  static const String paymentRestore = 'payment.restore';
  static const String paymentForceDelete = 'payment.forceDelete';
  static const String paymentRefund = 'payment.refund';
  static const String paymentVoid = 'payment.void';
  static const String paymentPrintReceipt = 'payment.print-receipt';
  static const String paymentExport = 'payment.export';

  static const String discountViewAny = 'discount.viewAny';
  static const String discountView = 'discount.view';
  static const String discountCreate = 'discount.create';
  static const String discountUpdate = 'discount.update';
  static const String discountDelete = 'discount.delete';
  static const String discountRestore = 'discount.restore';
  static const String discountForceDelete = 'discount.forceDelete';

  static const String taxViewAny = 'tax.viewAny';
  static const String taxView = 'tax.view';
  static const String taxCreate = 'tax.create';
  static const String taxUpdate = 'tax.update';
  static const String taxDelete = 'tax.delete';
  static const String taxRestore = 'tax.restore';
  static const String taxForceDelete = 'tax.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 📦 INVENTORY
  // ═══════════════════════════════════════════════════════════
  static const String inventoryViewAny = 'inventory.viewAny';
  static const String inventoryView = 'inventory.view';
  static const String inventoryCreate = 'inventory.create';
  static const String inventoryUpdate = 'inventory.update';
  static const String inventoryDelete = 'inventory.delete';
  static const String inventoryRestore = 'inventory.restore';
  static const String inventoryForceDelete = 'inventory.forceDelete';
  static const String inventoryAdjust = 'inventory.adjust';
  static const String inventoryTransfer = 'inventory.transfer';
  static const String inventoryStockIn = 'inventory.stock-in';
  static const String inventoryStockOut = 'inventory.stock-out';
  static const String inventoryExport = 'inventory.export';

  static const String inventoryCategoryViewAny = 'inventory-category.viewAny';
  static const String inventoryCategoryView = 'inventory-category.view';
  static const String inventoryCategoryCreate = 'inventory-category.create';
  static const String inventoryCategoryUpdate = 'inventory-category.update';
  static const String inventoryCategoryDelete = 'inventory-category.delete';
  static const String inventoryCategoryRestore = 'inventory-category.restore';
  static const String inventoryCategoryForceDelete =
      'inventory-category.forceDelete';

  static const String supplierViewAny = 'supplier.viewAny';
  static const String supplierView = 'supplier.view';
  static const String supplierCreate = 'supplier.create';
  static const String supplierUpdate = 'supplier.update';
  static const String supplierDelete = 'supplier.delete';
  static const String supplierRestore = 'supplier.restore';
  static const String supplierForceDelete = 'supplier.forceDelete';

  static const String purchaseOrderViewAny = 'purchase-order.viewAny';
  static const String purchaseOrderView = 'purchase-order.view';
  static const String purchaseOrderCreate = 'purchase-order.create';
  static const String purchaseOrderUpdate = 'purchase-order.update';
  static const String purchaseOrderDelete = 'purchase-order.delete';
  static const String purchaseOrderRestore = 'purchase-order.restore';
  static const String purchaseOrderForceDelete = 'purchase-order.forceDelete';
  static const String purchaseOrderApprove = 'purchase-order.approve';
  static const String purchaseOrderReceive = 'purchase-order.receive';
  static const String purchaseOrderCancel = 'purchase-order.cancel';

  // ═══════════════════════════════════════════════════════════
  // 👔 HR — EMPLOYEE / ATTENDANCE / LEAVE / PAYROLL
  // ═══════════════════════════════════════════════════════════
  static const String employeeViewAny = 'employee.viewAny';
  static const String employeeView = 'employee.view';
  static const String employeeCreate = 'employee.create';
  static const String employeeUpdate = 'employee.update';
  static const String employeeDelete = 'employee.delete';
  static const String employeeRestore = 'employee.restore';
  static const String employeeForceDelete = 'employee.forceDelete';
  static const String employeeImport = 'employee.import';
  static const String employeeExport = 'employee.export';

  static const String attendanceViewAny = 'attendance.viewAny';
  static const String attendanceView = 'attendance.view';
  static const String attendanceCreate = 'attendance.create';
  static const String attendanceUpdate = 'attendance.update';
  static const String attendanceDelete = 'attendance.delete';
  static const String attendanceRestore = 'attendance.restore';
  static const String attendanceForceDelete = 'attendance.forceDelete';
  static const String attendanceCheckIn = 'attendance.check-in';
  static const String attendanceCheckOut = 'attendance.check-out';

  static const String leaveRequestViewAny = 'leave-request.viewAny';
  static const String leaveRequestView = 'leave-request.view';
  static const String leaveRequestCreate = 'leave-request.create';
  static const String leaveRequestUpdate = 'leave-request.update';
  static const String leaveRequestDelete = 'leave-request.delete';
  static const String leaveRequestRestore = 'leave-request.restore';
  static const String leaveRequestForceDelete = 'leave-request.forceDelete';
  static const String leaveRequestPrepare = 'leave-request.prepare';
  static const String leaveRequestNote = 'leave-request.note';
  static const String leaveRequestApprove = 'leave-request.approve';
  static const String leaveRequestReceive = 'leave-request.receive';
  static const String leaveRequestReject = 'leave-request.reject';

  static const String payrollViewAny = 'payroll.viewAny';
  static const String payrollView = 'payroll.view';
  static const String payrollCreate = 'payroll.create';
  static const String payrollUpdate = 'payroll.update';
  static const String payrollDelete = 'payroll.delete';
  static const String payrollRestore = 'payroll.restore';
  static const String payrollForceDelete = 'payroll.forceDelete';
  static const String payrollGenerate = 'payroll.generate';
  static const String payrollApprove = 'payroll.approve';
  static const String payrollPay = 'payroll.pay';
  static const String payrollExport = 'payroll.export';

  // ═══════════════════════════════════════════════════════════
  // 🌐 LANDING PAGE CONTENT
  // ═══════════════════════════════════════════════════════════
  static const String serviceViewAny = 'service.viewAny';
  static const String serviceView = 'service.view';
  static const String serviceCreate = 'service.create';
  static const String serviceUpdate = 'service.update';
  static const String serviceDelete = 'service.delete';
  static const String serviceRestore = 'service.restore';
  static const String serviceForceDelete = 'service.forceDelete';

  static const String galleryViewAny = 'gallery.viewAny';
  static const String galleryView = 'gallery.view';
  static const String galleryCreate = 'gallery.create';
  static const String galleryUpdate = 'gallery.update';
  static const String galleryDelete = 'gallery.delete';
  static const String galleryRestore = 'gallery.restore';
  static const String galleryForceDelete = 'gallery.forceDelete';

  static const String testimonialViewAny = 'testimonial.viewAny';
  static const String testimonialView = 'testimonial.view';
  static const String testimonialCreate = 'testimonial.create';
  static const String testimonialUpdate = 'testimonial.update';
  static const String testimonialDelete = 'testimonial.delete';
  static const String testimonialRestore = 'testimonial.restore';
  static const String testimonialForceDelete = 'testimonial.forceDelete';
  static const String testimonialApprove = 'testimonial.approve';
  static const String testimonialReject = 'testimonial.reject';

  static const String announcementViewAny = 'announcement.viewAny';
  static const String announcementView = 'announcement.view';
  static const String announcementCreate = 'announcement.create';
  static const String announcementUpdate = 'announcement.update';
  static const String announcementDelete = 'announcement.delete';
  static const String announcementRestore = 'announcement.restore';
  static const String announcementForceDelete = 'announcement.forceDelete';
  static const String announcementPublish = 'announcement.publish';
  static const String announcementUnpublish = 'announcement.unpublish';

  static const String faqViewAny = 'faq.viewAny';
  static const String faqView = 'faq.view';
  static const String faqCreate = 'faq.create';
  static const String faqUpdate = 'faq.update';
  static const String faqDelete = 'faq.delete';
  static const String faqRestore = 'faq.restore';
  static const String faqForceDelete = 'faq.forceDelete';

  // ═══════════════════════════════════════════════════════════
  // 📊 REPORTS & ANALYTICS
  // ═══════════════════════════════════════════════════════════
  static const String reportView = 'report.view';
  static const String reportExport = 'report.export';
  static const String analyticsView = 'analytics.view';
  static const String financialReportView = 'financial-report.view';
  static const String financialReportExport = 'financial-report.export';
  static const String clinicalReportView = 'clinical-report.view';
  static const String clinicalReportExport = 'clinical-report.export';
  static const String inventoryReportView = 'inventory-report.view';
  static const String inventoryReportExport = 'inventory-report.export';
  static const String patientReportView = 'patient-report.view';
  static const String patientReportExport = 'patient-report.export';

  // ═══════════════════════════════════════════════════════════
  // 🔔 COMMUNICATIONS
  // ═══════════════════════════════════════════════════════════
  static const String smsSend = 'sms.send';
  static const String smsView = 'sms.view';
  static const String smsConfigure = 'sms.configure';

  static const String emailSend = 'email.send';
  static const String emailView = 'email.view';
  static const String emailConfigure = 'email.configure';

  static const String reminderViewAny = 'reminder.viewAny';
  static const String reminderView = 'reminder.view';
  static const String reminderCreate = 'reminder.create';
  static const String reminderUpdate = 'reminder.update';
  static const String reminderDelete = 'reminder.delete';
  static const String reminderRestore = 'reminder.restore';
  static const String reminderForceDelete = 'reminder.forceDelete';
  static const String reminderSend = 'reminder.send';

  // ═══════════════════════════════════════════════════════════
  // 🔧 SYSTEM
  // ═══════════════════════════════════════════════════════════
  static const String backupCreate = 'backup.create';
  static const String backupRestore = 'backup.restore';
  static const String backupDownload = 'backup.download';
  static const String backupDelete = 'backup.delete';
}
