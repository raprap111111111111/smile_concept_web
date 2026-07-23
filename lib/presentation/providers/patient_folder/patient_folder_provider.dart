// lib/presentation/providers/patient_folder/patient_folder_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/network/dio_client.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/data/services/patient_folder_service.dart';

// ═══════════════════════════════════════════════════════════
// STATE — Dedicated to a single folder view
// ═══════════════════════════════════════════════════════════
class PatientFolderState {
  final int? patientId;
  final String? patientName;
  final String? patientEmail;
  final List<PatientAttachment> attachments;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;

  // Filters
  final String? searchQuery;
  final String? categoryFilter;
  final String? scanStatusFilter;
  final String? fileTypeFilter;
  final bool? isXrayFilter;
  final String orderBy;
  final String orderDir;

  const PatientFolderState({
    this.patientId,
    this.patientName,
    this.patientEmail,
    this.attachments = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.searchQuery,
    this.categoryFilter,
    this.scanStatusFilter,
    this.fileTypeFilter,
    this.isXrayFilter,
    this.orderBy = 'created_at',
    this.orderDir = 'desc',
  });

  bool get hasMore => currentPage < lastPage;

  PatientFolderState copyWith({
    int? patientId,
    String? patientName,
    String? patientEmail,
    List<PatientAttachment>? attachments,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? searchQuery,
    String? categoryFilter,
    String? scanStatusFilter,
    String? fileTypeFilter,
    bool? isXrayFilter,
    String? orderBy,
    String? orderDir,
    bool clearError = false,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearScanStatus = false,
    bool clearFileType = false,
    bool clearIsXray = false,
  }) {
    return PatientFolderState(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      attachments: attachments ?? this.attachments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      scanStatusFilter: clearScanStatus
          ? null
          : (scanStatusFilter ?? this.scanStatusFilter),
      fileTypeFilter:
          clearFileType ? null : (fileTypeFilter ?? this.fileTypeFilter),
      isXrayFilter: clearIsXray ? null : (isXrayFilter ?? this.isXrayFilter),
      orderBy: orderBy ?? this.orderBy,
      orderDir: orderDir ?? this.orderDir,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════
class PatientFolderNotifier extends StateNotifier<PatientFolderState> {
  final PatientFolderService _service;

  PatientFolderNotifier(this._service) : super(const PatientFolderState());

  /// ✅ Open a patient folder (loads first page)
  Future<void> openFolder({
    required int patientId,
    String? patientName,
  }) async {
    debugPrint('📂 openFolder: patientId=$patientId, name=$patientName');

    // Reset state for new folder
    state = PatientFolderState(
      patientId: patientId,
      patientName: patientName,
    );

    await fetch();
  }

  /// Fetch attachments for the current folder
  Future<void> fetch({bool refresh = false}) async {
    if (state.patientId == null) {
      debugPrint('⚠️ fetch called but no patientId set');
      return;
    }

    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        attachments: [],
        clearError: true,
      );
    }

    state = state.copyWith(isLoading: true);

    debugPrint('📥 fetch — patientId: ${state.patientId}, page: ${state.currentPage}');

    try {
      final result = await _service.getFolderContents(
        userId: state.patientId!,
        page: state.currentPage,
        search: state.searchQuery,
        category: state.categoryFilter,
        scanStatus: state.scanStatusFilter,
        fileType: state.fileTypeFilter,
        isXray: state.isXrayFilter,
        orderBy: state.orderBy,
        orderDir: state.orderDir,
      );

      final dataMap = result['data'] as Map<String, dynamic>;
      final records = (dataMap['records'] as List?) ?? [];
      final patient = dataMap['patient'] as Map<String, dynamic>?;

      final incoming = records
          .map((e) => PatientAttachment.fromJson(e as Map<String, dynamic>))
          .toList();

      final merged = refresh ? incoming : [...state.attachments, ...incoming];

      state = state.copyWith(
        attachments: merged,
        currentPage: dataMap['current_page'] as int? ?? 1,
        lastPage: dataMap['last_page'] as int? ?? 1,
        total: dataMap['total'] as int? ?? 0,
        patientName: patient?['name'] as String? ?? state.patientName,
        patientEmail: patient?['email'] as String? ?? state.patientEmail,
        isLoading: false,
        clearError: true,
      );

      debugPrint('✅ Loaded ${incoming.length} files (total: ${state.total})');
    } catch (e, stack) {
      debugPrint('❌ fetch error: $e');
      debugPrint('📍 $stack');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetch();
  }

  Future<void> setSearch(String? query) async {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
    await fetch(refresh: true);
  }

  Future<void> setCategoryFilter(String? category) async {
    state = state.copyWith(
      categoryFilter: category,
      clearCategory: category == null,
    );
    await fetch(refresh: true);
  }

  Future<void> setScanStatusFilter(String? status) async {
    state = state.copyWith(
      scanStatusFilter: status,
      clearScanStatus: status == null,
    );
    await fetch(refresh: true);
  }

  Future<void> setFileTypeFilter(String? type) async {
    state = state.copyWith(
      fileTypeFilter: type,
      clearFileType: type == null,
    );
    await fetch(refresh: true);
  }

  Future<void> setIsXrayFilter(bool? isXray) async {
    state = state.copyWith(
      isXrayFilter: isXray,
      clearIsXray: isXray == null,
    );
    await fetch(refresh: true);
  }

  Future<void> setSort(String orderBy, String orderDir) async {
    state = state.copyWith(orderBy: orderBy, orderDir: orderDir);
    await fetch(refresh: true);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearSearch: true,
      clearCategory: true,
      clearScanStatus: true,
      clearFileType: true,
      clearIsXray: true,
      orderBy: 'created_at',
      orderDir: 'desc',
    );
    await fetch(refresh: true);
  }

  void reset() {
    state = const PatientFolderState();
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════

final patientFolderServiceProvider = Provider<PatientFolderService>((ref) {
  final dio = ref.watch(dioProvider);
  return PatientFolderService(dio);
});

final patientFolderProvider =
    StateNotifierProvider<PatientFolderNotifier, PatientFolderState>((ref) {
  return PatientFolderNotifier(ref.watch(patientFolderServiceProvider));
});