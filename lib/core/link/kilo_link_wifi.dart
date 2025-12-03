import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/head_state.dart';
import '../models/robot_event.dart';
import 'kilo_link.dart';

/// Simple HTTP-based KiloLink implementation.
///
/// Talks directly to the Python head backend on the Pi:
///   GET  /state
///   POST /setMode
///   POST /setEmotion
///
/// Drive commands are stubbed for now; they will be wired through Viam later.
class KiloLinkWifi implements KiloLink {
  KiloLinkWifi({
    required this.baseUrl,
    Duration pollInterval = const Duration(seconds: 1),
  }) : _pollInterval = pollInterval {
    _connectionStateController.add(false);
    _eventController = StreamController<RobotEvent>.broadcast();
    _startPolling();
  }

  /// Base URL, e.g. 'http://10.10.10.67:8090'.
  final String baseUrl;
  final Duration _pollInterval;

  final StreamController<bool> _connectionStateController =
  StreamController<bool>.broadcast();
  late final StreamController<RobotEvent> _eventController;

  HeadState _lastHeadState = HeadState.initial();
  bool _isDisposed = false;

  @override
  String get label => 'KiloLinkWifi($baseUrl)';

  @override
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<RobotEvent> get eventStream => _eventController.stream;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  void _startPolling() {
    Timer.periodic(_pollInterval, (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      try {
        final state = await getHeadState();
        final wasConnected = _lastHeadState.ok;
        final nowConnected = state.ok;

        _lastHeadState = state;

        if (nowConnected != wasConnected) {
          _connectionStateController.add(nowConnected);
          _eventController.add(RobotEvent(
            type: 'state',
            name: nowConnected ? 'link_up' : 'link_down',
            message: nowConnected
                ? 'Wi-Fi link to head backend is up.'
                : 'Wi-Fi link to head backend is down.',
            severity: nowConnected ? 'info' : 'warn',
          ));
        }
      } catch (e) {
        _connectionStateController.add(false);
        _eventController.add(RobotEvent(
          type: 'error',
          name: 'poll_failed',
          message: 'Failed to poll head state: $e',
          severity: 'error',
        ));
      }
    });
  }

  @override
  Future<HeadState> getHeadState() async {
    final uri = _uri('/state');
    final res = await http.get(uri).timeout(const Duration(seconds: 2));
    if (res.statusCode != 200) {
      return _lastHeadState.copyWith(ok: false);
    }

    final jsonBody = json.decode(res.body) as Map<String, dynamic>;
    final state = HeadState.fromJson(jsonBody);
    return state;
  }

  @override
  Future<void> setMode(String mode) async {
    final uri = _uri('/setMode');
    final body = json.encode({'mode': mode});
    final res = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(const Duration(seconds: 2));
    if (res.statusCode != 200) {
      throw Exception('setMode failed with HTTP ${res.statusCode}');
    }
  }

  @override
  Future<void> setEmotion(String emotion) async {
    final uri = _uri('/setEmotion');
    final body = json.encode({'emotion': emotion});
    final res = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(const Duration(seconds: 2));
    if (res.statusCode != 200) {
      throw Exception('setEmotion failed with HTTP ${res.statusCode}');
    }
  }

  @override
  Future<void> sendDriveCommand({
    required double linearMetersPerSec,
    required double angularDegPerSec,
  }) async {
    // Stub for now; will be wired into Viam later.
    _eventController.add(RobotEvent(
      type: 'info',
      name: 'drive_stub',
      message:
      'sendDriveCommand(linear=$linearMetersPerSec, angular=$angularDegPerSec) called on KiloLinkWifi (no-op for now).',
      severity: 'info',
    ));
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await _connectionStateController.close();
    await _eventController.close();
  }
}
