import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ── Environment Detection ─────────────────────────────
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // ── Base URL (from .env) ──────────────────────────────
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception(
        'API_BASE_URL not found in .env file!\n\n'
        'Fix:\n'
        '1. Create a .env file in project root\n'
        '2. Copy from .env.example: cp .env.example .env\n'
        '3. Set your backend URL\n'
        '4. Restart the app',
      );
    }

    return url;
  }

  // ── Timeouts ──────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Debug helper ──────────────────────────────────────
  static void printConfig() {
    // ignore: avoid_print
    print('''
╔════════════════════════════════════╗
║       API CONFIGURATION            ║
╠════════════════════════════════════╣
║ Environment : $environment
║ Base URL    : $baseUrl
╚════════════════════════════════════╝
''');
  }

  // Endpoints (these are appended to base URL)
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRegister = '/auth/register';
  static const String getProfile = '/profile';

  // ── Users / Profile ────────────────────────────────────────────
  static const String me = '/users/me';
  static const String users = '/users';

  // ── Patient Profiles ───────────────────────────────────────────
  static const String patientProfiles = '/patient-profiles';

  // ── Appointments (already have) ────────────────────────────────

  static const String getAppointments = '/appointments';
  static const String createAppointment = '/appointments';
  static const String getAvailableSlots = '/appointments/available-slots';

  static const String createPatients = '/profiles';

  static const String getPatients = '/patient-profiles';
  static const String getPatientProfile = '/patient-profiles';

  static const String getInvoices = '/invoices';
  static const String getPayments = '/payments';

  static const String getDentalCharts = '/dental-charts';
  static const String getClinicalNotes = '/clinical-notes';

  static const String getDoctors = '/doctors';
  static const String getDoctorSchedules = '/doctor-schedules';

  static const String getInventories = '/inventories';
  static const String getItems = '/items';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

enum Environment { development, staging, production }
