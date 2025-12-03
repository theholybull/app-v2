import 'package:flutter/foundation.dart';

/// Canonical representation of the head/face state as seen by the app.
///
/// This mirrors what the Pi head backend exposes at /state.
@immutable
class HeadState {
  final String mode;
  final String emotion;
  final String? eyesState;
  final DateTime? lastUpdate;
  final bool ok;

  const HeadState({
    required this.mode,
    required this.emotion,
    this.eyesState,
    this.lastUpdate,
    this.ok = true,
  });

  HeadState copyWith({
    String? mode,
    String? emotion,
    String? eyesState,
    DateTime? lastUpdate,
    bool? ok,
  }) {
    return HeadState(
      mode: mode ?? this.mode,
      emotion: emotion ?? this.emotion,
      eyesState: eyesState ?? this.eyesState,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      ok: ok ?? this.ok,
    );
  }

  factory HeadState.initial() {
    return const HeadState(
      mode: 'idle',
      emotion: 'neutral',
      eyesState: null,
      lastUpdate: null,
      ok: false,
    );
  }

  factory HeadState.fromJson(Map<String, dynamic> json) {
    return HeadState(
      mode: (json['mode'] ?? 'idle').toString(),
      emotion: (json['emotion'] ?? 'neutral').toString(),
      eyesState: json['eyes_state']?.toString(),
      lastUpdate: json['last_update'] is String
          ? DateTime.tryParse(json['last_update'] as String)
          : null,
      ok: json['ok'] is bool ? json['ok'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode,
      'emotion': emotion,
      if (eyesState != null) 'eyes_state': eyesState,
      if (lastUpdate != null) 'last_update': lastUpdate!.toIso8601String(),
      'ok': ok,
    };
  }

  @override
  String toString() =>
      'HeadState(mode=$mode, emotion=$emotion, eyesState=$eyesState, ok=$ok)';
}
