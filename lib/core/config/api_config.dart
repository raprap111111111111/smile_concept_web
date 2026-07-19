// lib/core/config/api_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ═══════════════════════════════════════════════════════
  // ENVIRONMENT DETECTION
  // ═══════════════════════════════════════════════════════
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // ═══════════════════════════════════════════════════════
  // BASE URL
  // ═══════════════════════════════════════════════════════
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'API_BASE_URL not found in .env file!\n\n'
        'Fix: cp .env.example .env and set your backend URL',
      );
    }
    return url;
  }

  // ═══════════════════════════════════════════════════════
  // STORAGE ROOT URL (for legacy public files)
  // ═══════════════════════════════════════════════════════
  static String get rootUrl {
    var url = baseUrl;
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    final apiVersionPattern = RegExp(r'/api/v\d+$');
    if (apiVersionPattern.hasMatch(url)) {
      url = url.replaceAll(apiVersionPattern, '');
    } else if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    }
    return url;
  }

  static String storageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$rootUrl/storage/$cleanPath';
  }

  // ═══════════════════════════════════════════════════════
  // ✅ ATTACHMENT URL HELPERS
  // ═══════════════════════════════════════════════════════
  static String attachmentFileUrl(int attachmentId) {
    return '$baseUrl$patientAttachments/$attachmentId/file';
  }

  static String attachmentDownloadUrl(int attachmentId) {
    return '$baseUrl$patientAttachments/$attachmentId/download';
  }

  static String attachmentThumbnailUrl(int attachmentId) {
    return '$baseUrl$patientAttachments/$attachmentId/thumbnail';
  }

  // ═══════════════════════════════════════════════════════
  // TIMEOUTS
  // ═══════════════════════════════════════════════════════
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════
  // DEBUG HELPER
  // ═══════════════════════════════════════════════════════
  static void printConfig() {
    // ignore: avoid_print
    print('''
╔════════════════════════════════════════════════════╗
║             API CONFIGURATION                      ║
╠════════════════════════════════════════════════════╣
║ Environment : $environment
║ Base URL    : $baseUrl
║ Root URL    : $rootUrl
║ Test Image  : ${storageUrl('patient-attachments/test.jpg')}
║ Test File   : ${attachmentFileUrl(1)}
╚════════════════════════════════════════════════════╝
''');
  }

  // ═══════════════════════════════════════════════════════
  // ENDPOINTS
  // ═══════════════════════════════════════════════════════
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRegister = '/auth/register';
  static const String getProfile = '/profile';

  static const String me = '/users/me';
  static const String users = '/users';

  static const String patientProfiles = '/patient-profiles';
  static const String createPatients = '/profiles';
  static const String getPatients = '/patient-profiles';
  static const String getPatientProfile = '/patient-profiles';

  static const String getAppointments = '/appointments';
  static const String createAppointment = '/appointments';
  static const String getAvailableSlots = '/appointments/available-slots';

  static const String getInvoices = '/invoices';
  static const String getPayments = '/payments';

  static const String getDentalCharts = '/dental-charts';
  static const String getClinicalNotes = '/clinical-notes';

  static const String getDoctors = '/doctors';
  static const String getDoctorSchedules = '/doctor-schedules';

  static const String getInventories = '/inventories';
  static const String getItems = '/items';

  // ✅ PATIENT ATTACHMENTS
  static const String patientAttachments = '/patient-attachments';
  static const String patientAttachmentsByPatient =
      '/patient-attachments/patients';
}

enum Environment { development, staging, production }
