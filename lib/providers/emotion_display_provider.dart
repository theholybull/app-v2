import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Represents the different emotional states the eyes can display.
enum Emotion {
  neutral,
  happy,
  sad,
  angry,
  surprised,
  listening,
  speaking,
  idle,
}

/// Represents which eye is being animated or updated.
enum EyeSide {
  left,
  right,
}

/// Represents the current state/properties of an eye (position, scale, etc.).
class EyeState {
  EyeState({
    required this.offset,
    required this.scale,
    required this.opacity,
    required this.rotation,
  });

  final Offset offset;
  final double scale;
  final double opacity;
  final double rotation;

  EyeState copyWith({
    Offset? offset,
    double? scale,
    double? opacity,
    double? rotation,
  }) {
    return EyeState(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// Provider that manages the animation and emotional state of the eyes.
///
/// This is where we blend:
///  - local random/idling eye motion,
///  - blinking,
///  - and (optionally) remote head-state from the Pi head backend.
class EmotionDisplayProvider extends ChangeNotifier {
  EmotionDisplayProvider({
    required TickerProvider vsync,
  }) : _vsync = vsync {
    _initAnimations();
    _startBlinking();
    _startRandomEyeMovements();
  }

  final TickerProvider _vsync;

  /// Animation controllers for various aspects of the eyes.
  late final AnimationController _blinkController;
  late final AnimationController _randomMovementController;

  /// Tracks left/right eye states.
  EyeState _leftEyeState = EyeState(
    offset: Offset.zero,
    scale: 1.0,
    opacity: 1.0,
    rotation: 0.0,
  );

  EyeState _rightEyeState = EyeState(
    offset: Offset.zero,
    scale: 1.0,
    opacity: 1.0,
    rotation: 0.0,
  );

  EyeState get leftEyeState => _leftEyeState;
  EyeState get rightEyeState => _rightEyeState;

  /// Current emotion being displayed.
  Emotion _currentEmotion = Emotion.neutral;
  Emotion get currentEmotion => _currentEmotion;

  /// Optional: callback to log or otherwise observe state changes.
  void Function(String message)? logger;

  /// HTTP/polling bits for talking to the Pi head backend.
  Timer? _headPollTimer;
  String? _headBaseUrl;

  /// Exposed for wiring up from the app:
  /// Set the base URL of the head backend, e.g. "http://kilo.local:8090".
  void setHeadBaseUrl(String? url) {
    _headBaseUrl = url?.trim().isEmpty ?? true ? null : url!.trim();
    _restartHeadBackendSync();
  }

  // ---- Initialization & Animation Setup ----

  void _initAnimations() {
    _blinkController = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 120),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blinkController.reverse();
      }
    });

    _randomMovementController = AnimationController(
      vsync: _vsync,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _randomMovementController.forward(from: 0.0);
      }
    });
  }

  // ---- Public Emotion / Mode API ----

  void setEmotion(Emotion emotion) {
    if (_currentEmotion == emotion) {
      return;
    }
    _currentEmotion = emotion;
    _applyEmotionToEyes(emotion);
    _log('Emotion changed -> $emotion');
    notifyListeners();
  }

  void showNeutral() => setEmotion(Emotion.neutral);
  void showHappy() => setEmotion(Emotion.happy);
  void showSad() => setEmotion(Emotion.sad);
  void showAngry() => setEmotion(Emotion.angry);
  void showSurprised() => setEmotion(Emotion.surprised);
  void showListening() => setEmotion(Emotion.listening);
  void showSpeaking() => setEmotion(Emotion.speaking);
  void showIdle() => setEmotion(Emotion.idle);

  // ---- Internal emotion → eye layout logic ----

  void _applyEmotionToEyes(Emotion emotion) {
    switch (emotion) {
      case Emotion.neutral:
        _setEyeStateBoth(
          offset: Offset.zero,
          scale: 1.0,
          opacity: 1.0,
          rotation: 0.0,
        );
        break;

      case Emotion.happy:
        _setEyeStateBoth(
          offset: const Offset(0, -2),
          scale: 1.05,
          opacity: 1.0,
          rotation: 0.0,
        );
        break;

      case Emotion.sad:
        _setEyeStateBoth(
          offset: const Offset(0, 2),
          scale: 0.95,
          opacity: 0.95,
          rotation: 0.1,
        );
        break;

      case Emotion.angry:
        _setEyeState(
          EyeSide.left,
          offset: const Offset(-1, -1),
          scale: 1.0,
          opacity: 1.0,
          rotation: -0.1,
        );
        _setEyeState(
          EyeSide.right,
          offset: const Offset(1, -1),
          scale: 1.0,
          opacity: 1.0,
          rotation: 0.1,
        );
        break;

      case Emotion.surprised:
        _setEyeStateBoth(
          offset: Offset.zero,
          scale: 1.1,
          opacity: 1.0,
          rotation: 0.0,
        );
        break;

      case Emotion.listening:
        _setEyeStateBoth(
          offset: const Offset(-1, 0),
          scale: 1.0,
          opacity: 1.0,
          rotation: -0.05,
        );
        break;

      case Emotion.speaking:
        _setEyeStateBoth(
          offset: const Offset(1, 0),
          scale: 1.0,
          opacity: 1.0,
          rotation: 0.05,
        );
        break;

      case Emotion.idle:
        _setEyeStateBoth(
          offset: const Offset(0, 0),
          scale: 1.0,
          opacity: 0.9,
          rotation: 0.0,
        );
        break;
    }
  }

  void _setEyeStateBoth({
    required Offset offset,
    required double scale,
    required double opacity,
    required double rotation,
  }) {
    _leftEyeState = EyeState(
      offset: offset,
      scale: scale,
      opacity: opacity,
      rotation: rotation,
    );
    _rightEyeState = EyeState(
      offset: offset,
      scale: scale,
      opacity: opacity,
      rotation: rotation,
    );
    notifyListeners();
  }

  void _setEyeState(
      EyeSide side, {
        required Offset offset,
        required double scale,
        required double opacity,
        required double rotation,
      }) {
    if (side == EyeSide.left) {
      _leftEyeState = EyeState(
        offset: offset,
        scale: scale,
        opacity: opacity,
        rotation: rotation,
      );
    } else {
      _rightEyeState = EyeState(
        offset: offset,
        scale: scale,
        opacity: opacity,
        rotation: rotation,
      );
    }
    notifyListeners();
  }

  // ---- Blinking ----

  void _startBlinking() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      _blink();
    });
  }

  void _blink() {
    if (_blinkController.isAnimating) return;

    _blinkController.forward(from: 0.0);
  }

  Animation<double> get blinkAnimation => Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(_blinkController);

  // ---- Random Eye Movements (idle wiggle) ----

  void _startRandomEyeMovements() {
    _randomMovementController.addListener(() {
      final t = _randomMovementController.value;
      final dx = math.sin(t * 2 * math.pi) * 1.5;
      final dy = math.cos(t * 2 * math.pi) * 1.5;

      _leftEyeState = _leftEyeState.copyWith(
        offset: Offset(dx, dy),
      );

      _rightEyeState = _rightEyeState.copyWith(
        offset: Offset(-dx, dy),
      );

      notifyListeners();
    });

    _randomMovementController.forward(from: 0.0);
  }

  // ---- Head Backend Sync (Pi head) ----

  void startHeadBackendSync() {
    if (kIsWeb) {
      _log('Head backend sync disabled on web.');
      return;
    }

    if (_headBaseUrl == null) {
      _log('Head backend base URL not set, not starting sync.');
      return;
    }

    _restartHeadBackendSync();
  }

  void _restartHeadBackendSync() {
    _headPollTimer?.cancel();
    _headPollTimer = null;

    if (kIsWeb) {
      return;
    }
    if (_headBaseUrl == null) {
      return;
    }

    _log('Starting head backend sync with base URL: $_headBaseUrl');

    _headPollTimer = Timer.periodic(
      const Duration(milliseconds: 500),
          (_) => _pollHeadState(),
    );
  }

  Future<void> _pollHeadState() async {
    final baseUrl = _headBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/state');

      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 2);

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        _log('Head backend /state returned ${response.statusCode}');
        httpClient.close();
        return;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      httpClient.close();

      if (responseBody.isEmpty) {
        _log('Head backend /state response body is empty.');
        return;
      }

      final decoded = json.decode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        _log('Head backend /state response is not a JSON object.');
        return;
      }

      _applyHeadState(decoded);
    } catch (e, st) {
      _log('Error polling head backend: $e\n$st');
    }
  }

  void _applyHeadState(Map<String, dynamic> state) {
    // The backend returns:
    // {
    //   "ok": true,
    //   "mode": "idle" | "listening" | "speaking" | ...,
    //   "emotion": "happy" | "neutral" | ...,
    //   "eyes_state": "idle" | "listening" | "speaking" | ...,
    //   "last_update": "2025-12-03T12:34:56Z"
    // }

    final ok = state['ok'] != false;
    if (!ok) {
      _log('Head backend state has ok=false, ignoring.');
      return;
    }

    final modeStr = (state['mode'] ?? '').toString().toLowerCase();
    final emotionStr = (state['emotion'] ?? '').toString().toLowerCase();

    // If eyes_state is present, we treat it as an additional hint
    // for emotion or simple "mode" mapping.
    if (state.containsKey('eyes_state')) {
      final eyes = state['eyes_state'];

      if (eyes is String && eyes.isNotEmpty) {
        _applyEyesStateString(eyes);
      }
    }

    // Map mode/emotion to our local Emotion enum.
    if (emotionStr.isNotEmpty) {
      final mapped = _mapEmotionString(emotionStr, modeStr);
      if (mapped != null && mapped != _currentEmotion) {
        setEmotion(mapped);
      }
    } else if (modeStr.isNotEmpty) {
      final mapped = _mapEmotionString('', modeStr);
      if (mapped != null && mapped != _currentEmotion) {
        setEmotion(mapped);
      }
    }
  }

  void _applyEyesStateString(String eyesState) {
    // Simple string-based eyes state mapping. This should match whatever
    // the Pi personality backend writes into "eyes_state" in head_state.json
    // or personality/state.json (e.g. "listening", "speaking", "idle").
    switch (eyesState.toLowerCase()) {
      case 'listening':
        showListening();
        break;
      case 'speaking':
        showSpeaking();
        break;
      case 'idle':
        showIdle();
        break;
      case 'happy':
        showHappy();
        break;
      case 'sad':
        showSad();
        break;
      case 'angry':
        showAngry();
        break;
      case 'surprised':
        showSurprised();
        break;
      case 'neutral':
      default:
        showNeutral();
        break;
    }
  }

  Emotion? _mapEmotionString(String emotion, String mode) {
    final e = emotion.toLowerCase();
    final m = mode.toLowerCase();

    // If the backend explicitly gave us an emotion string, trust that first.
    switch (e) {
      case 'happy':
        return Emotion.happy;
      case 'sad':
        return Emotion.sad;
      case 'angry':
        return Emotion.angry;
      case 'surprised':
        return Emotion.surprised;
      case 'listening':
        return Emotion.listening;
      case 'speaking':
        return Emotion.speaking;
      case 'idle':
        return Emotion.idle;
      case 'neutral':
        return Emotion.neutral;
    }

    // Otherwise infer from mode.
    switch (m) {
      case 'listening':
        return Emotion.listening;
      case 'speaking':
        return Emotion.speaking;
      case 'idle':
        return Emotion.idle;
      case 'happy':
        return Emotion.happy;
      case 'sad':
        return Emotion.sad;
      case 'angry':
        return Emotion.angry;
      case 'surprised':
        return Emotion.surprised;
      case 'neutral':
        return Emotion.neutral;
    }

    return null;
  }

  // ---- Logging helper ----

  void _log(String message) {
    if (logger != null) {
      logger!(message);
    } else {
      debugPrint('[EmotionDisplayProvider] $message');
    }
  }

  // ---- Lifecycle ----

  @override
  void dispose() {
    _blinkController.dispose();
    _randomMovementController.dispose();
    _headPollTimer?.cancel();
    super.dispose();
  }
}

