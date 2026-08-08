// lib/core/network/websocket/pusher_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'pusher_channel_authorizer.dart';
import 'pusher_connection_state.dart';
import 'pusher_event.dart';
import 'websocket_config.dart';

/// A private channel we want to be subscribed to, and how many listeners care.
class _ChannelRef {
  int listeners = 0;
  bool subscribed = false;

  /// Set when /broadcasting/auth returned 403. We stop re-attempting on
  /// reconnect so a role that simply lacks access doesn't hammer the endpoint.
  bool denied = false;
}

/// The Pusher wire protocol over a raw WebSocket.
///
/// `web_socket_channel` is transport only, so everything Pusher-shaped lives
/// here: the handshake, socket_id capture, private-channel auth, the
/// heartbeat, error classification, reconnection, and multiplexing one socket
/// across many independent listeners.
///
/// Deliberately Riverpod-free so it can be unit-tested standalone; the wiring
/// lives in websocket_providers.dart.
class PusherClient {
  PusherClient({
    required PusherChannelAuthorizer authorizer,
    Uri Function()? connectUriBuilder,
    void Function(String message)? log,
    this.maxBackoff = const Duration(seconds: 30),
    this.unavailableAfterAttempts = 3,
  })  : _authorizer = authorizer,
        _connectUriBuilder = connectUriBuilder ?? (() => WebsocketConfig.connectUri),
        _log = log ?? _noop;

  static void _noop(String _) {}

  final PusherChannelAuthorizer _authorizer;
  final Uri Function() _connectUriBuilder;
  final void Function(String) _log;

  /// Ceiling for reconnect backoff.
  final Duration maxBackoff;

  /// Consecutive failures before the state escalates from `reconnecting` to
  /// `unavailable`, which is what the UI surfaces.
  final int unavailableAfterAttempts;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _socketSub;

  final _events = StreamController<PusherEvent>.broadcast();
  final _states = StreamController<PusherConnectionState>.broadcast();

  final Map<String, _ChannelRef> _channels = {};

  PusherConnectionState _state = PusherConnectionState.idle;
  String? _socketId;
  int _attempt = 0;
  Timer? _reconnectTimer;
  Timer? _activityTimer;
  Timer? _pongTimer;

  /// Server-advertised idle window, replaced by the value in
  /// `pusher:connection_established`.
  Duration _activityTimeout = const Duration(seconds: 30);

  /// True once [disconnect] or [dispose] was called, so late socket callbacks
  /// don't resurrect the connection.
  bool _stopped = false;
  bool _disposed = false;

  final Random _random = Random();

  // ── Public surface ──────────────────────────────────────────

  PusherConnectionState get state => _state;

  /// Emits on every state transition. Seeded with the current value so a late
  /// listener isn't left blank until the next change.
  Stream<PusherConnectionState> get states async* {
    yield _state;
    yield* _states.stream;
  }

  String? get socketId => _socketId;

  /// Every application event on every subscribed channel.
  Stream<PusherEvent> get events => _events.stream;

  /// Opens the socket. Safe to call repeatedly — a live or in-flight
  /// connection is left alone.
  Future<void> connect() async {
    if (_disposed) return;

    if (!WebsocketConfig.isConfigured) {
      _log('REVERB_APP_KEY missing — real-time disabled, HTTP only.');
      return;
    }

    _stopped = false;

    if (_state == PusherConnectionState.connecting ||
        _state == PusherConnectionState.connected) {
      return;
    }

    await _open();
  }

  /// Closes the socket and clears all channel state.
  ///
  /// Call on logout: the next user must not inherit this user's subscriptions.
  Future<void> disconnect() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _attempt = 0;
    _channels.clear();
    await _teardownSocket();
    _setState(PusherConnectionState.idle);
  }

  /// Subscribes to [channel] if needed and calls [handler] for each [event].
  ///
  /// Cancelling the returned subscription releases this listener's claim on the
  /// channel; when the last one goes the client sends `pusher:unsubscribe`.
  StreamSubscription<PusherEvent> on(
    String channel,
    String event,
    void Function(PusherEvent) handler,
  ) {
    final ref = _channels.putIfAbsent(channel, _ChannelRef.new);
    ref.listeners++;

    // Ensure the wire subscription exists. If the socket isn't up yet this is a
    // no-op — _resubscribeAll() runs after the next successful handshake.
    if (_state.isLive && !ref.subscribed && !ref.denied) {
      _subscribe(channel);
    }

    // A pass-through controller is what makes cancellation observable: the
    // consumer cancels the outer subscription, onCancel fires, and we can drop
    // the channel reference. A plain .listen() gives no such hook.
    late final StreamSubscription<PusherEvent> inner;

    final controller = StreamController<PusherEvent>(
      onCancel: () async {
        await inner.cancel();
        _release(channel);
      },
    );

    inner = _events.stream
        .where((e) => e.channel == channel && e.event == event)
        .listen(controller.add, onError: controller.addError);

    return controller.stream.listen(handler);
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    _activityTimer?.cancel();
    _pongTimer?.cancel();
    await _events.close();
    await _states.close();
  }

  // ── Connection ──────────────────────────────────────────────

  Future<void> _open() async {
    _setState(_attempt == 0
        ? PusherConnectionState.connecting
        : (_attempt >= unavailableAfterAttempts
            ? PusherConnectionState.unavailable
            : PusherConnectionState.reconnecting));

    try {
      final socket = WebSocketChannel.connect(_connectUriBuilder());
      _socket = socket;

      // On web this is the only reliable way to learn the handshake failed;
      // the stream would otherwise just close with no useful error.
      await socket.ready;

      _socketSub = socket.stream.listen(
        _onFrame,
        onError: (Object error) => _onDropped('stream error: $error'),
        onDone: () => _onDropped('closed (${socket.closeCode})'),
        cancelOnError: false,
      );

      _log('socket open to ${WebsocketConfig.describe}');
      // State stays `connecting` until connection_established supplies the
      // socket_id — without it no private channel can be authorized.
    } catch (e) {
      _onDropped('connect failed: $e');
    }
  }

  Future<void> _teardownSocket() async {
    _activityTimer?.cancel();
    _pongTimer?.cancel();

    // Detach everything synchronously BEFORE the first await. If a reconnect
    // opened a new socket while we were suspended on one of these closes, a
    // later `_socket = null` would drop the replacement instead of the corpse.
    final sub = _socketSub;
    final socket = _socket;
    _socketSub = null;
    _socket = null;
    _socketId = null;

    await sub?.cancel();
    await socket?.sink.close();

    for (final ref in _channels.values) {
      ref.subscribed = false;
    }
  }

  void _onDropped(String reason) {
    if (_stopped || _disposed) return;
    if (_state == PusherConnectionState.failed) return;

    _log('socket dropped: $reason');
    _teardownSocket();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopped || _disposed) return;

    _reconnectTimer?.cancel();
    _attempt++;

    // Exponential backoff, capped, with jitter so many tabs reconnecting after
    // the same outage don't arrive in lockstep.
    final exponential = min(
      maxBackoff.inMilliseconds,
      1000 * pow(2, min(_attempt - 1, 10)).toInt(),
    );
    final delay = Duration(
      milliseconds: (exponential / 2).round() + _random.nextInt((exponential / 2).round() + 1),
    );

    _setState(_attempt >= unavailableAfterAttempts
        ? PusherConnectionState.unavailable
        : PusherConnectionState.reconnecting);

    _log('reconnect attempt $_attempt in ${delay.inMilliseconds}ms');
    _reconnectTimer = Timer(delay, _open);
  }

  /// Stops permanently. Used for errors no retry can fix.
  void _fail(String reason) {
    _log('fatal: $reason');
    _stopped = true;
    _reconnectTimer?.cancel();
    _teardownSocket();
    _setState(PusherConnectionState.failed);
  }

  void _setState(PusherConnectionState next) {
    if (_state == next) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  // ── Frames ──────────────────────────────────────────────────

  void _onFrame(dynamic raw) {
    if (raw is! String) return;

    _resetActivityTimer();

    final PusherEvent? event;
    try {
      event = PusherEvent.tryParse(raw);
    } on FormatException catch (e) {
      _log('undecodable frame ($e): $raw');
      return;
    }

    if (event == null) {
      _log('frame with no event name: $raw');
      return;
    }

    switch (event.event) {
      case 'pusher:connection_established':
        _onEstablished(event);
        break;

      case 'pusher:pong':
        // Activity timer already reset above; nothing else to do.
        break;

      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': <String, dynamic>{}});
        break;

      case 'pusher_internal:subscription_succeeded':
      case 'pusher:subscription_succeeded':
        if (event.channel != null) {
          _channels[event.channel!]?.subscribed = true;
          _log('subscribed to ${event.channel}');
        }
        break;

      case 'pusher_internal:subscription_error':
      case 'pusher:subscription_error':
        // Reverb's exact name for this frame is not guaranteed, hence both
        // spellings. Log verbatim so an unexpected shape is diagnosable.
        _log('subscription error on ${event.channel}: ${event.data}');
        if (event.channel != null) {
          _channels[event.channel!]?.subscribed = false;
        }
        break;

      case 'pusher:error':
        _onProtocolError(event);
        break;

      default:
        if (event.isProtocol) {
          _log('unhandled protocol frame: $raw');
          return;
        }
        // Application event — hand it to whoever is listening.
        if (!_events.isClosed) _events.add(event);
    }
  }

  void _onEstablished(PusherEvent event) {
    _socketId = event.data['socket_id']?.toString();

    final timeout = event.data['activity_timeout'];
    if (timeout is num && timeout > 0) {
      _activityTimeout = Duration(seconds: timeout.toInt());
    }

    if (_socketId == null) {
      // Without a socket_id nothing can be authorized, so treat it as a drop
      // rather than sitting in a half-open connection.
      _onDropped('connection_established had no socket_id');
      return;
    }

    _attempt = 0;
    _setState(PusherConnectionState.connected);
    _log('connected, socket_id=$_socketId, activity_timeout=${_activityTimeout.inSeconds}s');
    _resetActivityTimer();
    _resubscribeAll();
  }

  void _onProtocolError(PusherEvent event) {
    final code = (event.data['code'] as num?)?.toInt();
    final message = event.data['message']?.toString() ?? 'unknown';

    // Pusher reserves 4000-4099 for "do not reconnect" conditions: bad app key,
    // unsupported protocol version, app disabled. Retrying is pointless.
    if (code != null && code >= 4000 && code <= 4099) {
      _fail('pusher error $code: $message');
      return;
    }

    _log('pusher error ${code ?? "?"}: $message');
    _onDropped('pusher error ${code ?? "?"}');
  }

  // ── Heartbeat ───────────────────────────────────────────────

  /// Reverb expects a ping if the connection has been idle for
  /// `activity_timeout`. We send one, then require *any* frame back inside a
  /// short grace window — otherwise the socket is a black hole and gets
  /// recycled. This is what catches half-open connections, which neither
  /// `onDone` nor `onError` reports.
  void _resetActivityTimer() {
    _activityTimer?.cancel();
    _pongTimer?.cancel();

    if (_stopped || _disposed) return;

    _activityTimer = Timer(_activityTimeout, () {
      _send({'event': 'pusher:ping', 'data': <String, dynamic>{}});

      _pongTimer = Timer(const Duration(seconds: 10), () {
        _onDropped('no response to ping within 10s');
      });
    });
  }

  // ── Channels ────────────────────────────────────────────────

  void _resubscribeAll() {
    // Reverb keeps no message history, so anything sent while we were away is
    // gone. Callers are expected to resync on the `connected` transition; this
    // only restores the subscriptions themselves.
    for (final entry in _channels.entries) {
      if (entry.value.listeners > 0 && !entry.value.subscribed && !entry.value.denied) {
        _subscribe(entry.key);
      }
    }
  }

  Future<void> _subscribe(String channel) async {
    final socketId = _socketId;
    if (socketId == null || !_state.isLive) return;

    final ref = _channels[channel];
    if (ref == null || ref.denied) return;

    final result = await _authorizer.authorize(
      socketId: socketId,
      channelName: channel,
    );

    // The socket may have gone away while auth was in flight.
    if (_socketId != socketId || !_state.isLive) return;

    switch (result) {
      case ChannelAuthGranted(:final auth):
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': channel, 'auth': auth},
        });

      case ChannelAuthDenied():
        // Not entitled to this channel. Expected for optional channels — e.g.
        // a patient has no business on clinic.appointments — so this must not
        // degrade the connection.
        ref.denied = true;
        _log('channel $channel denied (403) — not subscribing');

      case ChannelAuthUnauthenticated():
        // The token is dead. Looping here would mean an endless 401 storm.
        _fail('/broadcasting/auth returned 401 for $channel');

      case ChannelAuthFailed(:final reason):
        _log('auth failed for $channel: $reason');
    }
  }

  void _release(String channel) {
    final ref = _channels[channel];
    if (ref == null) return;

    ref.listeners--;
    if (ref.listeners > 0) return;

    if (ref.subscribed && _state.isLive) {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channel},
      });
    }

    _channels.remove(channel);
  }

  void _send(Map<String, dynamic> frame) {
    final socket = _socket;
    if (socket == null) return;

    try {
      socket.sink.add(jsonEncode(frame));
    } catch (e) {
      _onDropped('send failed: $e');
    }
  }
}
