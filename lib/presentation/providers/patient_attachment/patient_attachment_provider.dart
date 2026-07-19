// lib/presentation/providers/patient_attachment/patient_attachment_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/data/services/patient_attachment_service.dart';
import '/core/network/dio_client.dart';
import 'package:file_picker/file_picker.dart';

// ═══════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════
class PatientAttachmentState {
  final List<PatientAttachment> attachments;
  final PatientAttachment? selected;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final String? searchQuery;
  final String? categoryFilter;
  final String? scanStatusFilter;
  final int? userIdFilter;

  const PatientAttachmentState({
    this.attachments = const [],
    this.selected,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.searchQuery,
    this.categoryFilter,
    this.scanStatusFilter,
    this.userIdFilter,
  });

  bool get hasMore => currentPage < lastPage;

  PatientAttachmentState copyWith({
    List<PatientAttachment>? attachments,
    PatientAttachment? selected,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
    String? searchQuery,
    String? categoryFilter,
    String? scanStatusFilter,
    int? userIdFilter,
    bool clearError = false,
    bool clearSelected = false,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearScanStatus = false,
    bool clearUserId = false,
  }) {
    return PatientAttachmentState(
      attachments: attachments ?? this.attachments,
      selected: clearSelected ? null : (selected ?? this.selected),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      scanStatusFilter: clearScanStatus
          ? null
          : (scanStatusFilter ?? this.scanStatusFilter),
      userIdFilter:
          clearUserId ? null : (userIdFilter ?? this.userIdFilter),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════
class PatientAttachmentNotifier
    extends StateNotifier<PatientAttachmentState> {
  final PatientAttachmentService _service;

  PatientAttachmentNotifier(this._service)
      : super(const PatientAttachmentState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(currentPage: 1, clearError: true);
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _service.getAll(
        page: state.currentPage,
        search: state.searchQuery,
        category: state.categoryFilter,
        scanStatus: state.scanStatusFilter,
        userId: state.userIdFilter,
      );

      final dataMap = result['data'] as Map<String, dynamic>;
      final records = (dataMap['records'] as List?) ?? [];

      debugPrint(
          '✅ Loaded ${records.length} attachments (page ${state.currentPage})');

      final incoming = records
          .map((e) =>
              PatientAttachment.fromJson(e as Map<String, dynamic>))
          .toList();

      final merged =
          refresh ? incoming : [...state.attachments, ...incoming];

      state = state.copyWith(
        attachments: merged,
        lastPage: dataMap['last_page'] as int? ?? 1,
        isLoading: false,
        clearError: true,
      );
    } catch (e, stack) {
      debugPrint('❌ fetchAll error: $e');
      debugPrint('📍 $stack');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.attachments.isEmpty) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchAll();
  }

  Future<void> fetchById(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final attachment = await _service.getById(id);
      state = state.copyWith(selected: attachment, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required int userId,
    int? appointmentId,
    required PlatformFile file,
    required String fileName,
    required String category,
    bool isXray = false,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.create(
        userId: userId,
        appointmentId: appointmentId,
        file: file,
        fileName: fileName,
        category: category,
        isXray: isXray,
        notes: notes,
      );
      await fetchAll(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        attachments:
            state.attachments.where((a) => a.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> setSearch(String? query) async {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
    await fetchAll(refresh: true);
  }

  Future<void> setCategoryFilter(String? category) async {
    state = state.copyWith(
      categoryFilter: category,
      clearCategory: category == null,
    );
    await fetchAll(refresh: true);
  }

  Future<void> setScanStatusFilter(String? status) async {
    state = state.copyWith(
      scanStatusFilter: status,
      clearScanStatus: status == null,
    );
    await fetchAll(refresh: true);
  }

  Future<void> setUserFilter(int? userId) async {
    state = state.copyWith(
      userIdFilter: userId,
      clearUserId: userId == null,
    );
    await fetchAll(refresh: true);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearSearch: true,
      clearCategory: true,
      clearScanStatus: true,
      clearUserId: true,
    );
    await fetchAll(refresh: true);
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════

final patientAttachmentServiceProvider =
    Provider<PatientAttachmentService>((ref) {
  final dio = ref.watch(dioProvider);
  return PatientAttachmentService(dio);
});

final patientAttachmentProvider =
    StateNotifierProvider<PatientAttachmentNotifier, PatientAttachmentState>(
        (ref) {
  return PatientAttachmentNotifier(
    ref.watch(patientAttachmentServiceProvider),
  );
});