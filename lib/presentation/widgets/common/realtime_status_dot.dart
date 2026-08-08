// lib/presentation/widgets/common/realtime_status_dot.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/websocket/pusher_connection_state.dart';
import '../../../core/network/websocket/websocket_providers.dart';
import '../../theme/app_colors.dart';

/// Shows a warning only when live updates are NOT working.
///
/// Renders nothing while healthy — a permanent "connected" light trains people
/// to ignore it, which defeats the point of showing it at all. A visible icon
/// means the screen may be stale and the refresh buttons are the way to be sure.
class RealtimeStatusDot extends ConsumerWidget {
  const RealtimeStatusDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(pusherConnectionStateProvider);

    final state = stateAsync.maybeWhen(
      data: (value) => value,
      orElse: () => PusherConnectionState.idle,
    );

    // idle means "no session yet" or "logged out", not a problem worth flagging.
    // connecting and reconnecting are usually momentary, so staying quiet avoids
    // a flicker on every navigation or brief blip.
    if (!state.isDegraded) return const SizedBox.shrink();

    final failed = state == PusherConnectionState.failed;

    return Tooltip(
      message: failed
          ? 'Live updates unavailable. Reload the page, or use refresh to see '
              'the latest.'
          : 'Reconnecting to live updates. Use refresh to see the latest.',
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          failed ? Icons.cloud_off_rounded : Icons.cloud_sync_outlined,
          size: 20,
          color: failed ? AppColors.error : AppColors.warning,
        ),
      ),
    );
  }
}
