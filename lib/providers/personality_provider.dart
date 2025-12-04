// lib/providers/personality_provider.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/personality/personality_models.dart';

/// Simple DTO for AI config mirrored with the Pi backend.
class AiConfig {
  final String baseUrl;
  final String apiKey; // stored on device, NOT re-shown in UI once saved
  final String model;
  final int maxTokens;
  final double temperature;
  final String systemPrompt;

  const AiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.maxTokens,
    required this.temperature,
    required this.systemPrompt,
  });

  AiConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
  }) {
    return AiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_url': baseUrl,
      'api_key': apiKey,
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'system_prompt': systemPrompt,
    };
  }

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      baseUrl: json['base_url'] as String? ?? '',
      apiKey: json['api_key'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4.1-mini',
      maxTokens: (json['max_tokens'] as num?)?.toInt() ?? 256,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      systemPrompt: json['system_prompt'] as String? ?? '',
    );
  }
}

class PersonalityProvider extends ChangeNotifier {
  final String piBaseUrl; // e.g. "http://kilo.local:8090" or "http://192.168.1.42:8090"

  PersonalityProfile _profile = const PersonalityProfile(
    id: 'default',
    displayName: 'Gail',
    adultModeEnabled: false,
    description: 'Garage AI assistant',
    humor: 0.6,
    snark: 0.4,
    warmth: 0.8,
  );

  AiConfig? _aiConfig;
  bool _isSavingConfig = false;
  bool _isChatting = false;
  String? _lastError;
  String? _lastReply;

  PersonalityProvider({required this.piBaseUrl});

  PersonalityProfile get profile => _profile;
  AiConfig? get aiConfig => _aiConfig;
  bool get hasAiConfig => _aiConfig != null;
  bool get isSavingConfig => _isSavingConfig;
  bool get isChatting => _isChatting;
  String? get lastError => _lastError;
  String? get lastReply => _lastReply;

  void updateProfile(PersonalityProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void setAdultMode(bool enabled) {
    _profile = _profile.copyWith(adultModeEnabled: enabled);
    notifyListeners();
  }

  void setAvatarPaths({
    String? avatarSpriteSheetPath,
    String? avatarMetaJsonPath,
    String? eyeSpriteSheetPath,
  }) {
    _profile = _profile.copyWith(
      avatarSpriteSheetPath: avatarSpriteSheetPath,
      avatarMetaJsonPath: avatarMetaJsonPath,
      eyeSpriteSheetPath: eyeSpriteSheetPath,
    );
    notifyListeners();
  }

  Future<void> fetchAiConfig() async {
    final uri = Uri.parse('$piBaseUrl/aiConfig');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        _lastError = 'AI config HTTP ${resp.statusCode}';
        notifyListeners();
        return;
      }
      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body['ok'] != true) {
        _lastError = body['error'] as String? ?? 'Unknown AI config error';
        notifyListeners();
        return;
      }
      final cfgJson = body['config'] as Map<String, dynamic>? ?? {};
      // Note: api_key is redacted from server, we keep whatever is already stored locally
      _aiConfig = AiConfig.fromJson(cfgJson).copyWith(
        apiKey: _aiConfig?.apiKey ?? '',
      );
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to fetch AI config: $e';
      notifyListeners();
    }
  }

  Future<void> saveAiConfig(AiConfig cfg) async {
    _isSavingConfig = true;
    _lastError = null;
    notifyListeners();

    final uri = Uri.parse('$piBaseUrl/setAiConfig');
    try:
    final resp = await http
        .post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(cfg.toJson()),
    )
        .timeout(const Duration(seconds: 10));

    final body = json.decode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || body['ok'] != true) {
    _lastError =
    body['error'] as String? ?? 'AI config save failed (HTTP ${resp.statusCode})';
    } else {
    _aiConfig = cfg;
    }
  } catch (e) {
  _lastError = 'Failed to save AI config: $e';
  } finally {
  _isSavingConfig = false;
  notifyListeners();
  }
}

Future<String?> sendChat(String userText) async {
  if (userText.trim().isEmpty) return null;
  _isChatting = true;
  _lastError = null;
  notifyListeners();

  final uri = Uri.parse('$piBaseUrl/chat');
  final msgs = <Map<String, String>>[
    {
      'role': 'user',
      'content': userText,
    },
  ];

  try {
    final resp = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'messages': msgs}),
    )
        .timeout(const Duration(seconds: 30));

    final body = json.decode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || body['ok'] != true) {
      _lastError =
          body['error'] as String? ?? 'Chat failed (HTTP ${resp.statusCode})';
      _lastReply = null;
    } else {
      _lastReply = body['reply'] as String? ?? '';
    }
  } catch (e) {
    _lastError = 'Chat error: $e';
    _lastReply = null;
  } finally {
    _isChatting = false;
    notifyListeners();
  }

  return _lastReply;
}
}
