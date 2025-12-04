// lib/providers/personality_provider.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Handles personality settings + simple chat relay to the Pi (or other backend).
///
/// The idea:
/// - App stays in control of persona/personality JSON and UI.
/// - This provider can optionally call a Pi-local AI endpoint, e.g. POST /chat.
/// - UI widgets (like PersonalityPanel) can bind to isChatting/lastError/lastReply.
class PersonalityProvider extends ChangeNotifier {
  final String piBaseUrl;

  bool _isChatting = false;
  String? _lastError;
  String? _lastReply;

  bool _adultMode = false;
  String _personaName = 'Default';
  String? _personaPath;
  String? _personaJson;

  PersonalityProvider({String? piBaseUrl})
      : piBaseUrl = piBaseUrl ?? 'http://kilo-head.local:8090';

  // --- Public read-only state ---

  bool get isChatting => _isChatting;
  String? get lastError => _lastError;
  String? get lastReply => _lastReply;

  bool get adultMode => _adultMode;
  String get personaName => _personaName;
  String? get personaPath => _personaPath;
  String? get personaJson => _personaJson;

  // --- Persona management (simple stubs that UI can call) ---

  void setAdultMode(bool value) {
    if (_adultMode == value) return;
    _adultMode = value;
    notifyListeners();
  }

  void setPersonaName(String name) {
    if (name.isEmpty || name == _personaName) return;
    _personaName = name;
    notifyListeners();
  }

  /// Load persona from a raw JSON string (e.g. uploaded file contents).
  void loadPersonaFromJson({required String jsonText, String? pathHint}) {
    _personaJson = jsonText;
    _personaPath = pathHint;
    notifyListeners();
  }

  // --- Chat / AI relay to Pi backend ---

  /// Send a chat message to the Pi (or other backend) and capture the reply.
  ///
  /// Expects the backend to respond with JSON like:
  ///   { "reply": "some string" }
  Future<void> sendChat(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;

    _isChatting = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$piBaseUrl/chat');

      final resp = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': msg,
          'adult_mode': _adultMode,
          'persona_name': _personaName,
        }),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        _lastError = 'HTTP ${resp.statusCode}: ${resp.body}';
        _lastReply = null;
      } else {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        _lastReply = body['reply'] as String? ?? '';
        _lastError = null;
      }
    } catch (e) {
      _lastError = 'Chat error: $e';
      _lastReply = null;
    } finally {
      _isChatting = false;
      notifyListeners();
    }
  }
}
