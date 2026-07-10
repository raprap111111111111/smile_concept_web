import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/appointment/appointment_model.dart';
import '../../../data/models/appointment/availability_model.dart';
import '../../../data/repositories/appointment_repository.dart';

// ============================================================================
// FILTER STATE
// ============================================================================

class AppointmentFilter {
  final String? search;
  final String? status;
  final int? doctorId;
  final int? branchId;
  final int? userId;
  final String? startDate;
  final String? endDate;

  const AppointmentFilter({
    this.search,
    this.status,
    this.doctorId,
    this.branchId,
    this.userId,
    this.startDate,
    this.endDate,
  });

  AppointmentFilter copyWith({
    String? search,
    String? status,
    int? doctorId,
    int? branchId,
    int? userId,
    String? startDate,
    String? endDate,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearDoctorId = false,
    bool clearBranchId = false,
    bool clearUserId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return AppointmentFilter(
      search: clearSearch ? null : search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      doctorId: clearDoctorId ? null : doctorId ?? this.doctorId,
      branchId: clearBranchId ? null : branchId ?? this.branchId,
      userId: clearUserId ? null : userId ?? this.userId,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
    );
  }
}

// ============================================================================
// APPOINTMENT LIST STATE
// ============================================================================

class AppointmentListState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasNextPage;
  final AppointmentFilter filter;
  final bool isUpdatingStatus;

  const AppointmentListState({
    this.appointments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasNextPage = false,
    this.filter = const AppointmentFilter(),
    this.isUpdatingStatus = false,
  });

  AppointmentListState copyWith({
    List<AppointmentModel>? appointments,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasNextPage,
    AppointmentFilter? filter,
    bool? isUpdatingStatus,
    bool clearError = false,
  }) {
    return AppointmentListState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      filter: filter ?? this.filter,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
    );
  }
}

// ============================================================================
// APPOINTMENT NOTIFIER
// ============================================================================

class AppointmentNotifier extends StateNotifier<AppointmentListState> {
  final AppointmentRepository _repository;

  AppointmentNotifier(this._repository) : super(const AppointmentListState());

  Future<void> load({bool reset = false}) async {
    if (reset) {
      state = state.copyWith(
        isLoading: true,
        appointments: [],
        currentPage: 1,
        clearError: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final result = await _repository.getAppointments(
        page: state.currentPage,
        status: state.filter.status,
        doctorId: state.filter.doctorId,
        branchId: state.filter.branchId,
        // ✅ DO NOT pass userId here either
        // Let backend handle it based on permissions
        startDate: state.filter.startDate,
        endDate: state.filter.endDate,
        search: state.filter.search,
      );

      state = state.copyWith(
        appointments:
            reset ? result.data : [...state.appointments, ...result.data],
        hasNextPage: result.hasNextPage,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isLoadingMore: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasNextPage) return;

    state = state.copyWith(
      currentPage: state.currentPage + 1,
      isLoadingMore: true,
    );

    await load();
  }

  Future<void> refresh() => load(reset: true);

  /// Old behavior: applies filter and immediately loads.
  /// Keep this if other pages still use it.
  void applyFilter(AppointmentFilter filter) {
    state = state.copyWith(filter: filter);
    load(reset: true);
  }

  /// New behavior: only updates filter.
  /// AppointmentsPage then manually calls loadForDate().
  void setFilter(AppointmentFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void addAppointment(AppointmentModel appointment) {
    state = state.copyWith(
      appointments: [appointment, ...state.appointments],
    );
  }

  void updateAppointment(AppointmentModel updated) {
    state = state.copyWith(
      appointments: state.appointments
          .map((appointment) =>
              appointment.id == updated.id ? updated : appointment)
          .toList(),
    );
  }

  Future<void> loadForDate(DateTime date) async {
    state = state.copyWith(
      isLoading: true,
      appointments: [],
      currentPage: 1,
      clearError: true,
    );

    try {
      final dateString = _formatDate(date);

      final result = await _repository.getAppointments(
        page: 1,
        pageSize: 50,
        search: state.filter.search,
        status: state.filter.status,
        doctorId: state.filter.doctorId,
        branchId: state.filter.branchId,
        // ✅ DO NOT pass userId here
        // Backend handles filtering based on canViewAny permission
        // If patient → backend forces where('user_id', authUserId)
        // If admin   → backend shows all
        startDate: dateString,
        endDate: dateString,
      );

      final selectedDayAppointments = result.data.where((appointment) {
        return _formatDate(appointment.startTime) == dateString;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      state = state.copyWith(
        isLoading: false,
        appointments: selectedDayAppointments,
        currentPage: result.currentPage,
        hasNextPage: result.hasNextPage,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void removeAppointment(int id) {
    state = state.copyWith(
      appointments: state.appointments
          .where((appointment) => appointment.id != id)
          .toList(),
    );
  }

  Future<bool> updateStatus({
    required int id,
    required String status,
    String? cancellationReason,
  }) async {
    state = state.copyWith(isUpdatingStatus: true, clearError: true);

    try {
      final updated = await _repository.updateAppointmentStatus(
        id: id,
        status: status,
        cancellationReason: cancellationReason,
      );

      state = state.copyWith(
        appointments: state.appointments
            .map((appointment) => appointment.id == id ? updated : appointment)
            .toList(),
        isUpdatingStatus: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isUpdatingStatus: false,
      );

      return false;
    }
  }
}

// ============================================================================
// AVAILABILITY STATE
// ============================================================================

class AvailabilityState {
  final List<TimeSlot> slots;
  final bool isLoading;
  final String? error;
  final TimeSlot? selectedSlot;

  const AvailabilityState({
    this.slots = const [],
    this.isLoading = false,
    this.error,
    this.selectedSlot,
  });

  AvailabilityState copyWith({
    List<TimeSlot>? slots,
    bool? isLoading,
    String? error,
    TimeSlot? selectedSlot,
    bool clearError = false,
    bool clearSlot = false,
  }) {
    return AvailabilityState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      selectedSlot: clearSlot ? null : selectedSlot ?? this.selectedSlot,
    );
  }

  List<TimeSlot> get availableSlots =>
      slots.where((slot) => slot.isAvailable).toList();
}

// ============================================================================
// AVAILABILITY NOTIFIER
// ============================================================================

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AppointmentRepository _repository;

  AvailabilityNotifier(this._repository) : super(const AvailabilityState());

  Future<void> fetchSlots({
    required int doctorId,
    required int branchId,
    required DateTime date,
  }) async {
    state = state.copyWith(
      isLoading: true,
      slots: [],
      clearError: true,
      clearSlot: true,
    );

    try {
      final result = await _repository.getAvailableSlots(
        doctorId: doctorId,
        branchId: branchId,
        date: date,
      );

      state = state.copyWith(
        slots: result.slots,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void clearSlots() {
    state = const AvailabilityState();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final appointmentNotifierProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentListState>((ref) {
  return AppointmentNotifier(ref.watch(appointmentRepositoryProvider));
});

final availabilityNotifierProvider =
    StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) {
  return AvailabilityNotifier(ref.watch(appointmentRepositoryProvider));
});
