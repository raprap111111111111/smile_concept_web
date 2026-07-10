import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  final authState = ref.watch(authStateProvider);
  return PermissionService(authState.user);
});

class PermissionService {
  final dynamic user;

  PermissionService(this.user);

  String get role {
    return user?.role?.toString().toLowerCase() ?? '';
  }

  bool get isSuperAdmin {
    return role == 'super-admin' ||
        role == 'super admin' ||
        user?.name?.toString().toLowerCase().contains('super admin') == true;
  }

  Set<String> get permissions {
    final raw = user?.permissions;

    if (raw is! List) return {};

    return raw.map<String>((item) {
      if (item is Map && item['name'] != null) {
        return item['name'].toString();
      }

      return item.toString();
    }).toSet();
  }

  bool can(String permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  bool canAny(List<String> items) {
    if (isSuperAdmin) return true;
    return items.any(can);
  }

  bool canAll(List<String> items) {
    if (isSuperAdmin) return true;
    return items.every(can);
  }
}