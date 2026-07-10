// lib/data/models/appointment/paginated_appointment_result.dart

import 'appointment_model.dart';

class PaginatedAppointmentResult {
  final List<AppointmentModel> data;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const PaginatedAppointmentResult({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  });
}