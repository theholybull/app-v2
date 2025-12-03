import 'dart:async';

import '../link/kilo_link.dart';
import '../models/head_state.dart';
import '../vision/vision_context.dart';
import 'personality_service.dart';

/// Simple, local, rule-based personality.
///
/// This does NOT call any external AI. It's the default brain that:
///   - reacts to presence/absence of faces,
///   - handles a tiny set of commands ("stop", "follow", etc.),
///   - generates short replies with a consistent tone.
class LocalPersonalityService implements PersonalityService {
  LocalPersonalityService({
    required this.link,
    Duration ambientInterval = const Duration(seconds: 20),
  }) : _ambientInterval = ambientInterval {
    _ambientController = StreamController<PersonalityResponse>.broadcast();
    _startAmbientLoop();
  }

  final KiloLink link;
  final Duration _ambientInterval;

  late final StreamController<PersonalityResponse> _ambientController;

  double _mood = 0.0; // -1.0 .. +1.0
  DateTime _lastUserInteraction = DateTime.now().toUtc();

  void _bumpMood(double delta) {
    _mood = (_mood + delta).clamp(-1.0, 1.0);
  }

  String _pickEmotion() {
    if (_mood > 0.4) return 'happy';
    if (_mood < -0.4) return 'annoyed';
    return 'neutral';
  }

  String _pickEyesState(HeadState head, VisionContext vision) {
    if (!vision.hasFaces) return 'idle_blink';
    if (vision.isSomeoneSmiling) return 'soft_smile';
    return 'focused';
  }

  Future<void> _startAmbientLoop() async {
    // Periodically emit "ambient" responses when user is present but quiet.
    while (true) {
      await Future<void>.delayed(_ambientInterval);
      final now = DateTime.now().toUtc();
      final silence = now.difference(_lastUserInteraction).inSeconds;
      if (silence < _ambientInterval.inSeconds ~/ 2) {
        continue; // user was talking recently, don't interject
      }

      // Later: we can pull VisionContext/head state here.
      // For now, just emit a soft "idle" suggestion when there's a face.
      // This will be wired to VisionService from outside.
    }
  }

  @override
  Stream<PersonalityResponse> get ambientSuggestions => _ambientController.stream;

  @override
  Future<PersonalityResponse> handleUserText({
    required String text,
    required VisionContext vision,
    required HeadState headState,
  }) async {
    _lastUserInteraction = DateTime.now().toUtc();

    final lower = text.trim().toLowerCase();
    String reply;
    String mode = headState.mode;
    String emotion = headState.emotion;

    // 1) Basic commands.
    if (lower.contains('stop')) {
      mode = 'idle';
      emotion = 'focused';
      reply = "Stopping. I'll chill right here.";
      await link.setMode(mode);
    } else if (lower.contains('follow')) {
      mode = 'follow';
      emotion = 'focused';
      reply = "Got it. I'll stick with you.";
      await link.setMode(mode);
    } else if (lower.contains('lights on')) {
      reply = "Lighting it up.";
      // Later: drive lights via KiloLink → Viam.
    } else if (lower.contains('lights off')) {
      reply = "Going low profile.";
      // Later: drive lights via KiloLink → Viam.
    } else {
      // 2) Small talk & presence-based responses.
      if (!vision.hasFaces) {
        _bumpMood(-0.05);
        reply = "Can't see you, but I'm still here.";
      } else if (vision.isSomeoneSmiling) {
        _bumpMood(0.1);
        reply = "There it is. I like that smile.";
      } else {
        reply = "Yeah, I'm with you. What do you want to do next?";
      }
    }

    // 3) Update mood + choose new emotion.
    _bumpMood(0.02); // small positive bump for any interaction
    emotion = _pickEmotion();
    final eyesState = _pickEyesState(headState, vision);

    // 4) Push emotion up to the Pi so everything stays in sync.
    await link.setEmotion(emotion);

    final response = PersonalityResponse(
      replyText: reply,
      mode: mode,
      emotion: emotion,
      eyesState: eyesState,
    );

    return response;
  }
}
