// lib/presentation/layouts/widgets/topbar/topbar_user_info.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth/auth_provider.dart';
import '../../../route/route_names.dart';

class TopbarUserInfo extends ConsumerWidget {
  const TopbarUserInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 19,
          backgroundImage: user?.profilePhotoUrl != null
              ? NetworkImage(user!.profilePhotoUrl!)
              : null,
          child: user?.profilePhotoUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 20)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user?.name ?? 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              user?.role ?? '',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 22),
        IconButton(
          tooltip: 'Logout',
          icon: Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.70)),
          onPressed: () async {
            await ref.read(authStateProvider.notifier).logout();
            if (context.mounted) context.goNamed(RouteNames.login);
          },
        ),
      ],
    );
  }
}