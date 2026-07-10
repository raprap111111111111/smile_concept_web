class BranchModel {
  final int id;
  final String name;
  final String? branchCode;
  final String? address;
  final String? city;
  final String? province;
  final String? phone;
  final String? email;
  final String? openingHours;
  final bool isActive;
  final int staffCount;
  final int appointmentsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BranchModel({
    required this.id,
    required this.name,
    this.branchCode,
    this.address,
    this.city,
    this.province,
    this.phone,
    this.email,
    this.openingHours,
    this.isActive = true,
    this.staffCount = 0,
    this.appointmentsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      branchCode: json['branch_code']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      province: json['province']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      openingHours: json['opening_hours']?.toString(),
      isActive: _asBool(json['is_active']),
      staffCount: _asInt(json['staff_count']),
      appointmentsCount: _asInt(json['appointments_count']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branch_code': branchCode,
      'address': address,
      'city': city,
      'province': province,
      'phone': phone,
      'email': email,
      'opening_hours': openingHours,
      'is_active': isActive,
      'staff_count': staffCount,
      'appointments_count': appointmentsCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toPayload() {
    return {
      'name': name,
      'branch_code': branchCode,
      'address': address,
      'city': city,
      'province': province,
      'phone': phone,
      'email': email,
      'opening_hours': openingHours,
      'is_active': isActive,
    };
  }

  String get fullAddress {
    return [
      address,
      city,
      province,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
  }

  BranchModel copyWith({
    int? id,
    String? name,
    String? branchCode,
    String? address,
    String? city,
    String? province,
    String? phone,
    String? email,
    String? openingHours,
    bool? isActive,
    int? staffCount,
    int? appointmentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      branchCode: branchCode ?? this.branchCode,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      openingHours: openingHours ?? this.openingHours,
      isActive: isActive ?? this.isActive,
      staffCount: staffCount ?? this.staffCount,
      appointmentsCount: appointmentsCount ?? this.appointmentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}