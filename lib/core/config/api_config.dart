class ApiConfig {
  // API Base URLs - MATCH YOUR POSTMAN CONFIG
  static const String baseUrlProduction = 'https://api.dpms.com/api';
  static const String baseUrlStaging = 'https://staging-api.dpms.com/api';
  static const String baseUrlDevelopment = 'http://localhost/api/v1'; 

  // Endpoints (these are appended to base URL)
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRegister = '/auth/register';
  static const String getProfile = '/profile';
  
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