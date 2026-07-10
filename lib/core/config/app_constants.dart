class AppConstants {
  // Authentication
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheItems = 100;
  
  // Appointment
  static const int appointmentReminderHours = 24;
  static const int maxAppointmentBookingDays = 90;
  static const int appointmentDurationMinutes = 30;
  static const int travelBufferMinutes = 15;
  
  // Pagination
  static const int pageSize = 20;
  
  // Error Messages
  static const String noInternetError = 'No internet connection';
  static const String unknownError = 'An unknown error occurred';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String unauthorizedError = 'Unauthorized access';
  static const String forbiddenError = 'Access forbidden';
  
  // Notification
  static const String reminderChannelId = 'appointment_reminders';
  static const String alertChannelId = 'system_alerts';
}