// lib/core/personality/personality_models.dart
import 'dart:convert';

/// Core personality profile used by both phone + Pi.
class PersonalityProfile {
  final String id;
  final String displayName;
  final bool adultModeEnabled;

  /// Short description shown in UI.
  final String description;

  /// Temper / style knobs (0–1).
  final double humor;        // 0 = dry, 1 = gremlin
  final double snark;        // 0 = nice, 1 = savage
  final double warmth;       // 0 = cold, 1 = cozy

  /// AI backend hints.
  final String? systemPromptOverride;

  /// Avatar / sprite config.
  final String? avatarSpriteSheetPath;
  final String? avatarMetaJsonPath;
  final String? eyeSpriteSheetPath;

  const PersonalityProfile({
    required this.id,
    required this.displayName,
    required this.adultModeEnabled,
    required this.description,
    required this.humor,
    required this.snark,
    required this.warmth,
    this.systemPromptOverride,
    this.avatarSpriteSheetPath,
    this.avatarMetaJsonPath,
    this.eyeSpriteSheetPath,
  });

  PersonalityProfile copyWith({
    String? id,
    String? displayName,
    bool? adultModeEnabled,
    String? description,
    double? humor,
    double? snark,
    double? warmth,
    String? systemPromptOverride,
    String? avatarSpriteSheetPath,
    String? avatarMetaJsonPath,
    String? eyeSpriteSheetPath,
  }) {
    return PersonalityProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      adultModeEnabled: adultModeEnabled ?? this.adultModeEnabled,
      description: description ?? this.description,
      humor: humor ?? this.humor,
      snark: snark ?? this.snark,
      warmth: warmth ?? this.warmth,
      systemPromptOverride: systemPromptOverride ?? this.systemPromptOverride,
      avatarSpriteSheetPath:
      avatarSpriteSheetPath ?? this.avatarSpriteSheetPath,
      avatarMetaJsonPath: avatarMetaJsonPath ?? this.avatarMetaJsonPath,
      eyeSpriteSheetPath: eyeSpriteSheetPath ?? this.eyeSpriteSheetPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'adultModeEnabled': adultModeEnabled,
      'description': description,
      'humor': humor,
      'snark': snark,
      'warmth': warmth,
      'systemPromptOverride': systemPromptOverride,
      'avatarSpriteSheetPath': avatarSpriteSheetPath,
      'avatarMetaJsonPath': avatarMetaJsonPath,
      'eyeSpriteSheetPath': eyeSpriteSheetPath,
    };
  }

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      id: json['id'] as String? ?? 'default',
      displayName: json['displayName'] as String? ?? 'Default',
      adultModeEnabled: json['adultModeEnabled'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      humor: (json['humor'] as num?)?.toDouble() ?? 0.5,
      snark: (json['snark'] as num?)?.toDouble() ?? 0.3,
      warmth: (json['warmth'] as num?)?.toDouble() ?? 0.8,
      systemPromptOverride: json['systemPromptOverride'] as String?,
      avatarSpriteSheetPath: json['avatarSpriteSheetPath'] as String?,
      avatarMetaJsonPath: json['avatarMetaJsonPath'] as String?,
      eyeSpriteSheetPath: json['eyeSpriteSheetPath'] as String?,
    );
  }

  static PersonalityProfile fromJsonString(String raw) {
    return PersonalityProfile.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );
  }

  String toJsonString() => json.encode(toJson());
}
