import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// High-level knobs for how the AI side behaves.
///
/// Keeps this generic so we can point it at:
///  * local Pi backend
///  * OpenRouter / proxy
///  * direct OpenAI if we really want to.
class AiConfig {
  final bool enableAi;
  final String apiType; // 'local', 'openai', 'openrouter', etc.
  final bool enableAdultMode;
  final String endpoint;
  final String? apiKey;
  final String? model;
  final String? spriteSheetPath;
  final String? idleAvatarPath;
  final String? talkingAvatarPath;

  const AiConfig({
    required this.enableAi,
    required this.apiType,
    required this.enableAdultMode,
    required this.endpoint,
    this.apiKey,
    this.model,
    this.spriteSheetPath,
    this.idleAvatarPath,
    this.talkingAvatarPath,
  });

  factory AiConfig.initial() => const AiConfig(
    enableAi: false,
    apiType: 'local',
    enableAdultMode: false,
    endpoint: 'http://kilo.local:8090',
    apiKey: null,
    model: null,
    spriteSheetPath: null,
    idleAvatarPath: null,
    talkingAvatarPath: null,
  );

  AiConfig copyWith({
    bool? enableAi,
    String? apiType,
    bool? enableAdultMode,
    String? endpoint,
    String? apiKey,
    String? model,
    String? spriteSheetPath,
    String? idleAvatarPath,
    String? talkingAvatarPath,
  }) {
    return AiConfig(
      enableAi: enableAi ?? this.enableAi,
      apiType: apiType ?? this.apiType,
      enableAdultMode: enableAdultMode ?? this.enableAdultMode,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      spriteSheetPath: spriteSheetPath ?? this.spriteSheetPath,
      idleAvatarPath: idleAvatarPath ?? this.idleAvatarPath,
      talkingAvatarPath: talkingAvatarPath ?? this.talkingAvatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableAi': enableAi,
      'apiType': apiType,
      'enableAdultMode': enableAdultMode,
      'endpoint': endpoint,
      'apiKey': apiKey,
      'model': model,
      'spriteSheetPath': spriteSheetPath,
      'idleAvatarPath': idleAvatarPath,
      'talkingAvatarPath': talkingAvatarPath,
    };
  }

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      enableAi: json['enableAi'] as bool? ?? false,
      apiType: json['apiType'] as String? ?? 'local',
      enableAdultMode: json['enableAdultMode'] as bool? ?? false,
      endpoint: json['endpoint'] as String? ?? 'http://kilo.local:8090',
      apiKey: json['apiKey'] as String?,
      model: json['model'] as String?,
      spriteSheetPath: json['spriteSheetPath'] as String?,
      idleAvatarPath: json['idleAvatarPath'] as String?,
      talkingAvatarPath: json['talkingAvatarPath'] as String?,
    );
  }
}

/// High-level description of the persona loaded from JSON on the Pi.
class PersonalityProfile {
  final String name;
  final String description;
  final String systemPrompt;
  final Map<String, dynamic> rawJson;

  const PersonalityProfile({
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.rawJson,
  });

  factory PersonalityProfile.empty() => const PersonalityProfile(
    name: 'Default',
    description: 'Base personality',
    systemPrompt: '',
    rawJson: <String, dynamic>{},
  );

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      name: json['name'] as String? ?? 'Default',
      description: json['description'] as String? ?? '',
      systemPrompt: json['systemPrompt'] as String? ?? '',
      rawJson: json,
    );
  }
}

/// Glue between the phone UI and the Pi personality backend.
class PersonalityProvider extends ChangeNotifier {
  /// Base URL of the Pi backend. Default is mDNS for now.
  ///
  /// Example: http://kilo.local:8090
  String piBaseUrl;

  PersonalityProfile _profile = PersonalityProfile.empty();
  AiConfig _aiConfig = AiConfig.initial();

  bool _isSavingConfig = false;
  bool _isChatting = false;
  String? _lastError;
  String? _lastReply;

  PersonalityProvider({String? piBaseUrl})
      : piBaseUrl = piBaseUrl ?? 'http://kilo.local:8090';

  PersonalityProfile get profile => _profile;
  AiConfig get aiConfig => _aiConfig;
  bool get isSavingConfig => _isSavingConfig;
  bool get isChatting => _isChatting;
  String? get lastError => _lastError;
  String? get lastReply => _lastReply;

  /// Later, PiConnectionProvider can call this so we don’t hard-code forever.
  void setPiBaseUrl(String url) {
    if (url == piBaseUrl) return;
    piBaseUrl = url;
    notifyListeners();
  }

  Uri _buildUri(String path) {
    final base = piBaseUrl.endsWith('/')
        ? piBaseUrl.substring(0, piBaseUrl.length - 1)
        : piBaseUrl;
    return Uri.parse('$base$path');
  }

  Future<void> loadProfile() async {
    try {
      final res = await http
          .get(_buildUri('/personality/profile'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final jsonMap = json.decode(res.body) as Map<String, dynamic>;
        _profile = PersonalityProfile.fromJson(jsonMap);
        _lastError = null;
      } else {
        _lastError = 'Profile HTTP ${res.statusCode}';
      }
    } catch (e) {
      _lastError = 'Profile load failed: $e';
    }
    notifyListeners();
  }

  Future<void> fetchAiConfig() async {
    try {
      final res = await http
          .get(_buildUri('/personality/ai-config'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final jsonMap = json.decode(res.body) as Map<String, dynamic>;
        _aiConfig = AiConfig.fromJson(jsonMap);
        _lastError = null;
      } else {
        _lastError = 'Config HTTP ${res.statusCode}';
      }
    } catch (e) {
      _lastError = 'Config load failed: $e';
    }
    notifyListeners();
  }

  Future<void> saveAiConfig(AiConfig cfg) async {
    _isSavingConfig = true;
    _lastError = null;
    notifyListeners();
    try {
      final res = await http.post(
        _buildUri('/personality/ai-config'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode(cfg.toJson()),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        _aiConfig = cfg;
      } else {
        _lastError = 'Save failed: HTTP ${res.statusCode}';
      }
    } catch (e) {
      _lastError = 'Save failed: $e';
    } finally {
      _isSavingConfig = false;
      notifyListeners();
    }
  }

  /// Update just the avatar / sprite paths.
  void setAvatarPaths({
    String? spriteSheetPath,
    String? idleAvatarPath,
    String? talkingAvatarPath,
  }) {
    _aiConfig = _aiConfig.copyWith(
      spriteSheetPath: spriteSheetPath ?? _aiConfig.spriteSheetPath,
      idleAvatarPath: idleAvatarPath ?? _aiConfig.idleAvatarPath,
      talkingAvatarPath: talkingAvatarPath ?? _aiConfig.talkingAvatarPath,
    );
    notifyListeners();
  }

  Future<String?> sendChat(String prompt) async {
    if (prompt.trim().isEmpty) return null;

    _isChatting = true;
    _lastError = null;
    _lastReply = null;
    notifyListeners();

    try {
      final res = await http.post(
        _buildUri('/chat'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'profile': _profile.rawJson,
          'config': _aiConfig.toJson(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        _lastReply = body['reply'] as String? ?? '';
      } else {
        _lastError = 'Chat failed: HTTP ${res.statusCode}';
      }
    } catch (e) {
      _lastError = 'Chat failed: $e';
    } finally {
      _isChatting = false;
      notifyListeners();
    }

    return _lastReply;
  }
}
