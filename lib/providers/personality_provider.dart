import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Simple personality profile: who the avatar "is".
class PersonalityProfile {
  String displayName;
  String role;
  String backstory;
  String style;
  bool adultMode; // true -> adult / spicy mode allowed

  PersonalityProfile({
    this.displayName = 'Gail',
    this.role = 'Garage AI liaison',
    this.backstory =
    'Born in the glow of fluorescent shop lights and the smell of 80W-90.',
    this.style = 'Gritty, nostalgic, straight-talking but kind.',
    this.adultMode = false,
  });

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      displayName: json['displayName'] as String? ?? 'Gail',
      role: json['role'] as String? ?? 'Garage AI liaison',
      backstory: json['backstory'] as String? ?? '',
      style: json['style'] as String? ?? '',
      adultMode: json['adultMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'role': role,
    'backstory': backstory,
    'style': style,
    'adultMode': adultMode,
  };
}

/// Config for talking to your AI backend (OpenAI, local, etc.).
class AiConfig {
  String baseUrl; // e.g. http://kilo.local:8091 or https://api.openai.com
  String model;
  String apiKey;
  double temperature;
  int maxTokens;
  String providerId; // 'openai', 'local', etc.

  AiConfig({
    this.baseUrl = '',
    this.model = 'gpt-4.1-mini',
    this.apiKey = '',
    this.temperature = 0.7,
    this.maxTokens = 512,
    this.providerId = 'openai',
  });

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4.1-mini',
      apiKey: json['apiKey'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 512,
      providerId: json['providerId'] as String? ?? 'openai',
    );
  }

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'model': model,
    'apiKey': apiKey,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'providerId': providerId,
  };
}

/// Sprite / avatar paths (these live on the device or Pi and are consumed
/// by your avatar renderer).
class AvatarPaths {
  String idle;
  String talking;
  String thinking;

  AvatarPaths({
    this.idle = '',
    this.talking = '',
    this.thinking = '',
  });

  factory AvatarPaths.fromJson(Map<String, dynamic> json) {
    return AvatarPaths(
      idle: json['idle'] as String? ?? '',
      talking: json['talking'] as String? ?? '',
      thinking: json['thinking'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'idle': idle,
    'talking': talking,
    'thinking': thinking,
  };
}

/// Main provider driving the personality / AI / avatar config.
class PersonalityProvider extends ChangeNotifier {
  PersonalityProvider({required this.piBaseUrl});

  /// Base URL for the Pi head backend (e.g. http://kilo.local:8090).
  final String piBaseUrl;

  PersonalityProfile _profile = PersonalityProfile();
  AiConfig _aiConfig = AiConfig();
  AvatarPaths _avatarPaths = AvatarPaths();

  bool _isSavingConfig = false;
  bool _isChatting = false;
  String? _lastError;
  String? _lastReply;

  // ---- Public getters used by the widgets ----

  PersonalityProfile get profile => _profile;
  AiConfig get aiConfig => _aiConfig;
  AvatarPaths get avatarPaths => _avatarPaths;

  bool get isSavingConfig => _isSavingConfig;
  bool get isChatting => _isChatting;
  String? get lastError => _lastError;
  String? get lastReply => _lastReply;

  // ---- Simple helpers ----

  Uri _buildPiUri(String path) {
    if (piBaseUrl.isEmpty) {
      // This lets the app still run without a Pi; calls will just no-op.
      throw StateError('piBaseUrl is not configured');
    }
    return Uri.parse('$piBaseUrl$path');
  }

  // ---- Profile editing ----

  void updateProfile({
    String? displayName,
    String? role,
    String? backstory,
    String? style,
    bool? adultMode,
  }) {
    _profile = PersonalityProfile(
      displayName: displayName ?? _profile.displayName,
      role: role ?? _profile.role,
      backstory: backstory ?? _profile.backstory,
      style: style ?? _profile.style,
      adultMode: adultMode ?? _profile.adultMode,
    );
    notifyListeners();
  }

  // ---- Avatar paths ----

  void setAvatarPaths({
    String? idle,
    String? talking,
    String? thinking,
  }) {
    _avatarPaths = AvatarPaths(
      idle: idle ?? _avatarPaths.idle,
      talking: talking ?? _avatarPaths.talking,
      thinking: thinking ?? _avatarPaths.thinking,
    );
    notifyListeners();
  }

  // ---- AI config load/save against Pi ----

  Future<void> fetchAiConfig() async {
    try {
      final uri = _buildPiUri('/personality/ai-config');
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        _aiConfig = AiConfig.fromJson(data['aiConfig'] as Map<String, dynamic>);
        if (data['profile'] is Map<String, dynamic>) {
          _profile =
              PersonalityProfile.fromJson(data['profile'] as Map<String, dynamic>);
        }
        if (data['avatar'] is Map<String, dynamic>) {
          _avatarPaths =
              AvatarPaths.fromJson(data['avatar'] as Map<String, dynamic>);
        }
        _lastError = null;
      } else {
        _lastError = 'Failed to load AI config (${resp.statusCode})';
      }
    } catch (e) {
      // If Pi isn’t there yet, we don’t hard-fail — just stash the error.
      _lastError = 'Error loading AI config: $e';
    }
    notifyListeners();
  }

  Future<void> saveAiConfig(AiConfig cfg) async {
    _isSavingConfig = true;
    _lastError = null;
    _aiConfig = cfg;
    notifyListeners();

    try {
      final uri = _buildPiUri('/personality/ai-config');
      final body = json.encode({
        'aiConfig': _aiConfig.toJson(),
        'profile': _profile.toJson(),
        'avatar': _avatarPaths.toJson(),
      });
      final resp = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _lastError = null;
      } else {
        _lastError = 'Save failed (${resp.statusCode})';
      }
    } catch (e) {
      _lastError = 'Error saving AI config: $e';
    } finally {
      _isSavingConfig = false;
      notifyListeners();
    }
  }

  // ---- Chat ----

  /// Send a quick chat to the Pi backend. The Pi side is expected to expose
  /// POST /chat { message, profile, aiConfig, mode } -> { reply }.
  Future<void> sendChat(String message) async {
    if (message.trim().isEmpty) return;

    _isChatting = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = _buildPiUri('/chat');
      final body = json.encode({
        'message': message,
        'profile': _profile.toJson(),
        'aiConfig': _aiConfig.toJson(),
        'mode': _profile.adultMode ? 'adult' : 'safe',
      });

      final resp = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        _lastReply = data['reply'] as String? ?? '';
        _lastError = null;
      } else {
        _lastReply = null;
        _lastError = 'Chat failed (${resp.statusCode})';
      }
    } catch (e) {
      _lastReply = null;
      _lastError = 'Chat error: $e';
    } finally {
      _isChatting = false;
      notifyListeners();
    }
  }
}
