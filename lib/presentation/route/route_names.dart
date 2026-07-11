// lib/presentation/route/route_names.dart
class RouteNames {
  RouteNames._();

  // ── Auth / Public ─────────────────────────────────────────────────────
  static const String splash = 'splash';
  static const String landing = 'landing';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String home = 'home';
  static const String unauthorized = 'unauthorized';

  // ── Dashboard ─────────────────────────────────────────────────────────
  static const String dashboard = 'dashboard';

  // ── Appointments ──────────────────────────────────────────────────────
  static const String appointments = 'appointments';
  static const String bookAppointment = 'bookAppointment';
  static const String appointmentDetail = 'appointmentDetail';

  // ── Patients ──────────────────────────────────────────────────────────
  static const String patients = 'patients';
  static const String patientCreate = 'patient-create';
  static const String patientDetail = 'patient-detail';
  static const String patientEdit = 'patient-edit';
  static const String patientProfile = 'patientProfile';

  // ── Doctors ───────────────────────────────────────────────────────────
  static const String doctors = 'doctors';
  static const String doctorSchedules = 'doctor-schedules';
  static const String dentalChart = 'dentalChart';

  // ── Clinical ──────────────────────────────────────────────────────────
  static const String clinical = 'clinical';
  static const String prescriptions = 'prescriptions';       // ✅ ADDED
  static const String treatmentPlans = 'treatment-plans';    // ✅ ADDED
  static const String treatments = 'treatments';             // ✅ ADDED

  // ── Services ──────────────────────────────────────────────────────────
  static const String services = 'services';

  // ── Billing ───────────────────────────────────────────────────────────
  static const String invoices = 'invoices';
  static const String invoiceDetail = 'invoice-detail';
  static const String payments = 'payments';

  // ── Operations ────────────────────────────────────────────────────────
  static const String inventory = 'inventory';
  static const String branches = 'branches';
  static const String labCases = 'lab-cases';

  // ── System ────────────────────────────────────────────────────────────
  static const String settings = 'settings';
  static const String roles = 'roles';
  static const String users = 'users';
  static const String activityLogs = 'activity-logs';
  static const String security = 'security';
  static const String backup = 'backup';
  static const String notifications = 'notifications';

  // ── Patient Self-Service (optional dedicated routes) ──────────────────
  static const String myProfile = 'my-profile';
  static const String myAppointments = 'my-appointments';
  static const String myInvoices = 'my-invoices';
}