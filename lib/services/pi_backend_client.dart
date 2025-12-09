// lib/services/pi_backend_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple snapshot of Pi head state.
class PiState {
  final String mode;
  final String emotion;
  final DateTime? lastUpdate;

  PiState({
    required this.mode,
    required this.emotion,
    this.lastUpdate,
  });

  factory PiState.fromJson(Map<String, dynamic> json) {
    return PiState(
      mode: (json['mode'] as String?) ?? 'idle',
      emotion: (json['emotion'] as String?) ?? 'neutral',
      lastUpdate: json['last_update'] != null
          ? DateTime.tryParse(json['last_update'] as String)
          : null,
    );
  }
}

/// Thin HTTP client around kilo-head-backend on the Pi.
///
/// NOTE: `host` is treated as the *full base URL*, e.g.:
///   "http://10.10.10.67:8090"
class PiBackendClient {
  final String _baseUrl;
  final int port; // currently unused, kept for compatibility

  PiBackendClient({required String host, this.port = 8090})
      : _baseUrl = host;

  Uri _buildUri(String path) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$base$path');
  }

  Future<Map<String, dynamic>> health() async {
    final uri = _buildUri('/health');
    final resp =
    await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) {
      throw Exception('Bad status from /health: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<PiState> getState() async {
    final uri = _buildUri('/state');
    final resp =
    await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) {
      throw Exception('Bad status from /state: ${resp.statusCode}');
    }
    final body = json.decode(resp.body) as Map<String, dynamic>;
    return PiState.fromJson(body);
  }

  Future<void> setEmotion(String emotion) async {
    final uri = _buildUri('/setEmotion');
    final resp = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'emotion': emotion}),
    )
        .timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception('setEmotion failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> setMode(String mode) async {
    final uri = _buildUri('/setMode');
    final resp = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'mode': mode}),
    )
        .timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception('setMode failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Phone → Pi sensor snapshot.
  ///
  /// Payload shape:
  /// {
  ///   "ts": "...",
  ///   "orientation": {...},
  ///   "accel": {...},
  ///   "gps": {...},
  ///   "altitude_m": ...,
  ///   "phone_battery": ...
  /// }
  Future<void> postSensors(Map<String, dynamic> payload) async {
    final uri = _buildUri('/sensors');
    final resp = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: json.encode(payload),
    )
        .timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception('postSensors failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Generic event pipe Phone ↔ Pi.
  ///
  /// Example:
  ///   await postEvent(
  ///     type: 'face.friend_seen',
  ///     payload: {'label': 'Josh', 'confidence': 0.94},
  ///   );
  Future<void> postEvent({
    required String type,
    String source = 'phone',
    Map<String, dynamic>? payload,
  }) async {
    final uri = _buildUri('/events');
    final body = <String, dynamic>{
      'source': source,
      'type': type,
      if (payload != null) 'payload': payload,
    };

    final resp = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: json.encode(body),
    )
        .timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception('postEvent failed: ${resp.statusCode} ${resp.body}');
    }
  }
}
