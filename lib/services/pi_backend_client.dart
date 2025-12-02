import 'dart:convert';
import 'package:http/http.dart' as http;

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
      mode: (json['mode'] ?? 'idle').toString(),
      emotion: (json['emotion'] ?? 'neutral').toString(),
      lastUpdate: json['last_update'] != null
          ? DateTime.tryParse(json['last_update'].toString())
          : null,
    );
  }
}

class PiBackendClient {
  final String host; // e.g. "10.10.10.67" or full URL
  final int port;    // e.g. 8090

  PiBackendClient({
    required this.host,
    required this.port,
  });

  Uri _buildUri(String path) {
    final trimmed = host.trim();

    // If host is a full URL, trust it and just append path.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final base = Uri.parse(trimmed);
      return base.replace(path: path);
    }

    // Bare host/IP.
    return Uri.parse('http://$trimmed:$port$path');
  }

  Future<bool> checkHealth() async {
    final uri = _buildUri('/health');
    final resp = await http.get(uri).timeout(const Duration(seconds: 3));
    if (resp.statusCode != 200) return false;
    final body = json.decode(resp.body) as Map<String, dynamic>;
    return (body['ok'] == true);
  }

  Future<PiState> getState() async {
    final uri = _buildUri('/state');
    final resp = await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) {
      throw Exception('Bad status from /state: ${resp.statusCode}');
    }
    final body = json.decode(resp.body) as Map<String, dynamic>;
    return PiState.fromJson(body);
  }

  Future<void> setEmotion(String emotion) async {
    final uri = _buildUri('/setEmotion');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'emotion': emotion}),
    ).timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception('setEmotion failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> setMode(String mode) async {
    final uri = _buildUri('/setMode');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'mode': mode}),
    ).timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception('setMode failed: ${resp.statusCode} ${resp.body}');
    }
  }
}
