import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/permission_provider.dart';

class PermissionGate extends ConsumerWidget {
  final String? permission;
  final List<String>? any;
  final List<String>? all;
  final Widget child;
  final Widget fallback;

  const PermissionGate({
    super.key,
    this.permission,
    this.any,
    this.all,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(permissionServiceProvider);

    bool allowed = true;

    if (permission != null) {
      allowed = service.can(permission!);
    }

    if (any != null) {
      allowed = service.canAny(any!);
    }

    if (all != null) {
      allowed = service.canAll(all!);
    }

    return allowed ? child : fallback;
  }
}