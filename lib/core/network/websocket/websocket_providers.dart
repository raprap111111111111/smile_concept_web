// lib/core/network/websocket/websocket_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/logger.dart';
import '../dio_client.dart';
import 'pusher_channel_authorizer.dart';
import 'pusher_client.dart';
import 'pusher_connection_state.dart';

final pusherAuthorizerProvider = Provider<PusherChannelAuthorizer>((ref) {
  // The one app-wide Dio, so the Passport token and interceptors are reused.
  return PusherChannelAuthorizer(ref.watch(dioProvider));
});

/// The single app-wide socket.
///
/// Deliberately NOT autoDispose. An autoDispose socket would be torn down every
/// time the last watching widget unmounted — including during ordinary
/// go_router transitions — producing a reconnect storm. The ProviderScope in
/// main.dart owns this for the app's lifetime; the auth lifecycle is handled by
/// RealtimeBridge, not by provider disposal.
final pusherClientProvider = Provider<PusherClient>((ref) {
  final client = PusherClient(
    authorizer: ref.watch(pusherAuthorizerProvider),
    log: (message) => AppLogger.debug('[ws] $message'),
  );

  ref.onDispose(client.dispose);

  return client;
});

/// Connection status for the UI.
///
/// The only StreamProvider in the codebase, and appropriately so: this is
/// derived read-only state with no writer. Feature data flows through the
/// existing StateNotifiers instead, which avoids creating a second source of
/// truth that would then need reconciling.
final pusherConnectionStateProvider =
    StreamProvider<PusherConnectionState>((ref) {
  return ref.watch(pusherClientProvider).states;
});
