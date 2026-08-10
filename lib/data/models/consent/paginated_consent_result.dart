import 'patient_consent_model.dart';

class PaginatedConsentResult {
  final List<PatientConsentModel> records;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;

  const PaginatedConsentResult({
    required this.records,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  factory PaginatedConsentResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['records'];
    final list = (rawList is List) ? rawList : const [];

    return PaginatedConsentResult(
      records: list
          .whereType<Map<String, dynamic>>()
          .map(PatientConsentModel.fromJson)
          .toList(),
      total:   _toInt(json['total'])   ?? 0,
      offset:  _toInt(json['offset'])  ?? 0,
      limit:   _toInt(json['limit'])   ?? 0,
      hasMore: (json['has_more'] as bool?) ?? false,
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