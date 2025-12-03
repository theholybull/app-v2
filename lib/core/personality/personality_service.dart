import 'dart:async';

import '../models/head_state.dart';
import '../vision/vision_context.dart';

/// High-level result from the personality engine.
class PersonalityResponse {
  final String replyText;
  final String mode; // e.g. "idle", "chat", "drive"
  final String emotion; // e.g. "happy", "annoyed"
  final String? eyesState;

  PersonalityResponse({
    required this.replyText,
    required this.mode,
    required this.emotion,
    this.eyesState,
  });
}

/// Abstract personality / AI bridge.
///
/// Implementations can:
///   - Use local rules only
///   - Call OpenAI or any user-configured HTTP LLM
///   - Blend both
abstract class PersonalityService {
  /// Called when new text comes in (from STT or typing),
  /// plus the latest vision + head state.
  Future<PersonalityResponse> handleUserText({
    required String text,
    required VisionContext vision,
    required HeadState headState,
  });

  /// Stream of "ambient" suggestions (e.g. when user is idle but present).
  Stream<PersonalityResponse> get ambientSuggestions;
}
