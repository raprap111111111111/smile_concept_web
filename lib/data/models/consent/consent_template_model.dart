class ConsentTemplateModel {
  final int id;
  final String title;
  final String body;
  final bool isActive;
  final DateTime? createdAt;

  const ConsentTemplateModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isActive,
    this.createdAt,
  });

  factory ConsentTemplateModel.fromJson(Map<String, dynamic> json) {
    return ConsentTemplateModel(
      id:       _toInt(json['id']) ?? 0,
      title:    (json['title'] as String?) ?? 'Untitled',
      body:     (json['body']  as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
      };
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}