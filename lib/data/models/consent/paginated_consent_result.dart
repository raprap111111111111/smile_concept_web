// lib/data/models/consent/paginated_consent_result.dart
import 'patient_consent_model.dart';

class PaginatedConsentResult {
  final List<PatientConsentModel> records;
  final int  total;
  final int  perPage;
  final int  currentPage;
  final int  lastPage;
  final bool hasMore;

  /// Legacy fields — kept for backwards compatibility
  final int offset;
  final int limit;

  const PaginatedConsentResult({
    required this.records,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
    this.offset = 0,
    this.limit  = 0,
  });

  factory PaginatedConsentResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['records'];
    final list = (rawList is List) ? rawList : const [];

    final perPage     = _toInt(json['per_page'])     ?? 15;
    final currentPage = _toInt(json['current_page']) ?? 1;

    return PaginatedConsentResult(
      records: list
          .whereType<Map<String, dynamic>>()
          .map(PatientConsentModel.fromJson)
          .toList(),
      total:       _toInt(json['total'])        ?? 0,
      perPage:     perPage,
      currentPage: currentPage,
      lastPage:    _toInt(json['last_page'])    ?? 1,
      hasMore:     (json['has_more'] as bool?)  ?? false,
      offset:      (currentPage - 1) * perPage,
      limit:       perPage,
    );
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}