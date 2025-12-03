import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';

enum Emotion {
  happy,
  sad,
  angry,
  surprised,
  neutral,
  curious,
  focused,
  sleepy,
  excited,
  confused,
}

enum EyeState {
  open,
  halfOpen,
  closed,
  blinking,
  looking,
  tracking,
}

class EmotionDisplayProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  Emotion _currentEmotion = Emotion.neutral;
  EyeState _eyeState = EyeState.open;
  double _eyeX = 0.0; // -1 to 1 (left to right)
  double _eyeY = 0.0; // -1 to 1 (up to down)
  double _steeringAngle = 0.0; // -45 to 45 degrees
  bool _isTracking = false;
  String? _trackedPersonId;
  Timer? _blinkTimer;
  Timer? _emotionTimer;
  Timer? _trackingTimer;

  // Eye animation parameters
  double _blinkProgress = 0.0;
  bool _isBlinking = false;
  double _pupilSize = 0.3;
  double _eyeOpenness = 1.0;

  // Emotion transition parameters
  double _emotionIntensity = 0.0;
  Emotion? _targetEmotion;

  // Head backend integration
  String? _headBaseUrl;
  Timer? _headPollTimer;

  // Getters
  Emotion get currentEmotion => _currentEmotion;
  EyeState get eyeState => _eyeState;
  double get eyeX => _eyeX;
  double get eyeY => _eyeY;
  double get steeringAngle => _steeringAngle;
  bool get isTracking => _isTracking;
  String? get trackedPersonId => _trackedPersonId;
  double get blinkProgress => _blinkProgress;
  bool get isBlinking => _isBlinking;
  double get pupilSize => _pupilSize;
  double get eyeOpenness => _eyeOpenness;
  double get emotionIntensity => _emotionIntensity;

  Future<void> initialize() async {
    _logger.i('Initializing emotion display provider...');

    // Start automatic blinking
    _startBlinking();

    // Start random eye movements
    _startRandomEyeMovements();

    // Set initial neutral emotion
    setEmotion(Emotion.neutral);
  }

  // ========= HEAD BACKEND SYNC =========

  void startHeadBackendSync(String baseUrl) {
    _logger.i('Starting head backend sync with base URL: $baseUrl');
    _headBaseUrl = baseUrl;
    _headPollTimer?.cancel();
    _headPollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _pollHeadState();
    });
  }

  void stopHeadBackendSync() {
    _logger.i('Stopping head backend sync');
    _headPollTimer?.cancel();
    _headPollTimer = null;
    _headBaseUrl = null;
  }

  Future<void> _pollHeadState() async {
    final base = _headBaseUrl;
    if (base == null || base.isEmpty) return;

    try {
      final uri = Uri.parse('$base/state');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 1);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(const Utf8Decoder()).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        _applyHeadState(data);
      }

      client.close();
    } catch (e) {
      _logger.w('Error polling head backend: $e');
    }
  }

  void _applyHeadState(Map<String, dynamic> data) {
    final emotionStr = (data['emotion'] ?? '').toString().toLowerCase().trim();
    final eyesStr = (data['eyes_state'] ?? '').toString().toLowerCase().trim();
    final modeStr = (data['mode'] ?? '').toString().toLowerCase().trim();

    if (emotionStr.isNotEmpty) {
      final mapped = _mapEmotionString(emotionStr, modeStr);
      // IMPORTANT: only change if different, so we don't
      // restart the transition on every poll.
      if (mapped != null && mapped != _currentEmotion) {
        setEmotion(mapped);
      }
    }

    if (eyesStr.isNotEmpty) {
      _applyEyesStateString(eyesStr);
    }
  }

  Emotion? _mapEmotionString(String emotion, String mode) {
    switch (emotion) {
      case 'happy':
      case 'smile':
        return Emotion.happy;
      case 'sad':
        return Emotion.sad;
      case 'angry':
      case 'mad':
        return Emotion.angry;
      case 'surprised':
      case 'shock':
        return Emotion.surprised;
      case 'curious':
        return Emotion.curious;
      case 'focused':
        return Emotion.focused;
      case 'sleepy':
      case 'tired':
        return Emotion.sleepy;
      case 'excited':
        return Emotion.excited;
      case 'confused':
        return Emotion.confused;
      default:
        return Emotion.neutral;
    }
  }

  void _applyEyesStateString(String eyes) {
    // While we're mid-blink, don't let remote state stomp the animation.
    if (_isBlinking) {
      return;
    }

    EyeState newState;
    switch (eyes) {
      case 'listen':
        newState = EyeState.looking;
        break;
      case 'speak':
      // We *could* force blinking here, but that fights the local blink logic.
      // Just treat "speak" as an attentive/open state visually.
        newState = EyeState.open;
        break;
      case 'idle':
      default:
        newState = EyeState.open;
        break;
    }

    if (newState != _eyeState) {
      _eyeState = newState;
      notifyListeners();
    }
  }

  // ========= CORE EMOTION / EYES LOGIC =========

  void setEmotion(Emotion emotion, {double intensity = 1.0}) {
    _logger.i('Setting emotion to: $emotion with intensity: $intensity');

    _targetEmotion = emotion;
    _emotionIntensity = intensity;

    _animateEmotionTransition();
  }

  void _animateEmotionTransition() {
    if (_targetEmotion == null) return;

    const transitionDuration = Duration(milliseconds: 500);
    const steps = 20;
    final stepDuration = transitionDuration.inMilliseconds ~/ steps;

    _emotionTimer?.cancel();

    int currentStep = 0;
    final Emotion targetEmotion = _targetEmotion!;

    _emotionTimer = Timer.periodic(
      Duration(milliseconds: stepDuration),
          (timer) {
        currentStep++;

        final t = currentStep / steps;

        // Pupil/eye openness based on target emotion
        switch (targetEmotion) {
          case Emotion.happy:
          case Emotion.excited:
            _pupilSize = 0.4 + (0.2 * _emotionIntensity);
            _eyeOpenness = 1.0;
            break;
          case Emotion.sad:
          case Emotion.sleepy:
            _pupilSize = 0.3;
            _eyeOpenness = 0.7;
            break;
          case Emotion.angry:
            _pupilSize = 0.2;
            _eyeOpenness = 0.8;
            break;
          case Emotion.surprised:
            _pupilSize = 0.5;
            _eyeOpenness = 1.0;
            break;
          case Emotion.curious:
          case Emotion.focused:
            _pupilSize = 0.3 + (0.1 * _emotionIntensity);
            _eyeOpenness = 0.9;
            break;
          case Emotion.neutral:
          case Emotion.confused:
            _pupilSize = 0.3;
            _eyeOpenness = 1.0;
            break;
        }

        if (t >= 1.0) {
          _currentEmotion = targetEmotion;
          timer.cancel();
        } else {
          _currentEmotion = targetEmotion;
        }

        notifyListeners();
      },
    );
  }

  void setEyeState(EyeState state) {
    _logger.i('Setting eye state to: $state');
    _eyeState = state;
    notifyListeners();
  }

  void setEyePosition(double x, double y) {
    _logger.i('Setting eye position to: ($x, $y)');
    _eyeX = x.clamp(-1.0, 1.0);
    _eyeY = y.clamp(-1.0, 1.0);
    notifyListeners();
  }

  void setSteeringAngle(double angle) {
    _logger.i('Setting steering angle to: $angle');
    _steeringAngle = angle.clamp(-45.0, 45.0);
    notifyListeners();
  }

  void startTrackingPerson(String personId) {
    _logger.i('Starting to track person: $personId');
    _isTracking = true;
    _trackedPersonId = personId;
    _eyeState = EyeState.tracking;

    _startTrackingAnimation();

    notifyListeners();
  }

  void stopTracking() {
    _logger.i('Stopping person tracking');
    _isTracking = false;
    _trackedPersonId = null;
    _eyeState = EyeState.open;

    _trackingTimer?.cancel();
    _trackingTimer = null;

    setEyePosition(0.0, 0.0);

    notifyListeners();
  }

  void _startTrackingAnimation() {
    _trackingTimer?.cancel();

    _trackingTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        if (!_isTracking) {
          timer.cancel();
          return;
        }

        final random = Random();
        final targetX = (random.nextDouble() * 2 - 1) * 0.5;
        final targetY = (random.nextDouble() * 2 - 1) * 0.5;

        _eyeX = _eyeX + (targetX - _eyeX) * 0.3;
        _eyeY = _eyeY + (targetY - _eyeY) * 0.3;

        notifyListeners();
      },
    );
  }

  void _startBlinking() {
    _blinkTimer?.cancel();

    _blinkTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        if (_isBlinking) {
          _updateBlinkAnimation();
        } else {
          if (Random().nextDouble() < 0.05) {
            _startBlinkAnimation();
          }
        }
      },
    );
  }

  void _startBlinkAnimation() {
    _isBlinking = true;
    _blinkProgress = 0.0;
    _eyeState = EyeState.blinking;

    _logger.d('Starting blink animation');
  }

  void _updateBlinkAnimation() {
    const blinkSpeed = 0.2;
    _blinkProgress += blinkSpeed;

    if (_blinkProgress >= 1.0) {
      _isBlinking = false;
      _blinkProgress = 0.0;
      _eyeState = EyeState.open;
      _eyeOpenness = 1.0;

      _logger.d('Blink animation completed');
    } else {
      if (_blinkProgress < 0.5) {
        _eyeOpenness = 1.0 - (_blinkProgress * 2);
      } else {
        _eyeOpenness = (_blinkProgress - 0.5) * 2;
      }
    }

    notifyListeners();
  }

  void _startRandomEyeMovements() {
    Timer.periodic(
      const Duration(milliseconds: 1500),
          (timer) {
        if (_isTracking) return;

        final random = Random();
        final newX = (random.nextDouble() * 2 - 1) * 0.7;
        final newY = (random.nextDouble() * 2 - 1) * 0.5;

        setEyePosition(newX, newY);
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': _currentEmotion.toString(),
      'eye_state': _eyeState.toString(),
      'eye_x': _eyeX,
      'eye_y': _eyeY,
      'steering_angle': _steeringAngle,
      'is_tracking': _isTracking,
      'tracked_person_id': _trackedPersonId,
      'blink_progress': _blinkProgress,
      'is_blinking': _isBlinking,
      'pupil_size': _pupilSize,
      'eye_openness': _eyeOpenness,
      'emotion_intensity': _emotionIntensity,
    };
  }

  // ===== various update integrations (unchanged behavior) =====

  void updateFromSensorData({
    double? steeringAngle,
    bool? isMoving,
    double? speed,
  }) {
    if (steeringAngle != null) {
      setSteeringAngle(steeringAngle);
    }

    if (isMoving != null && speed != null) {
      if (isMoving && speed > 0.1) {
        _eyeOpenness = (1.0 - (speed / 100.0)).clamp(0.6, 1.0);

        if (speed > 20.0) {
          setEmotion(Emotion.excited, intensity: 0.7);
        } else if (speed > 5.0) {
          setEmotion(Emotion.curious, intensity: 0.5);
        }
      } else {
        _eyeOpenness = 1.0;
      }
    }

    notifyListeners();
  }

  void updateForObstacleDetection({
    bool? obstacleDetected,
    double? obstacleDistance,
  }) {
    if (obstacleDetected == true) {
      _eyeState = EyeState.looking;
      setEmotion(Emotion.curious, intensity: 0.6);

      if (obstacleDistance != null && obstacleDistance < 1.0) {
        setEmotion(Emotion.surprised, intensity: 0.8);
      }
    } else {
      _eyeState = EyeState.open;
    }

    notifyListeners();
  }

  void updateForFaceDetection({
    bool? faceDetected,
    bool? isRecognized,
    String? personId,
  }) {
    if (faceDetected == true) {
      if (isRecognized == true && personId != null) {
        startTrackingPerson(personId);
        setEmotion(Emotion.happy, intensity: 0.8);
      } else {
        _eyeState = EyeState.looking;
        setEmotion(Emotion.curious, intensity: 0.6);
      }
    } else {
      stopTracking();
      setEmotion(Emotion.neutral);
    }

    notifyListeners();
  }

  void updateForSystemState({
    bool? isConnectedToPi,
    bool? isViamConnected,
  }) {
    if (isConnectedToPi == false || isViamConnected == false) {
      setEmotion(Emotion.confused, intensity: 0.7);
      _eyeState = EyeState.halfOpen;
    } else {
      if (_currentEmotion == Emotion.confused) {
        setEmotion(Emotion.neutral);
        _eyeState = EyeState.open;
      }
    }

    notifyListeners();
  }

  void updateForAudioLevel(double audioLevel) {
    _pupilSize = (0.3 + (audioLevel * 0.3)).clamp(0.2, 0.6);
    _eyeOpenness = (1.0 - (audioLevel * 0.2)).clamp(0.8, 1.0);
    notifyListeners();
  }

  void updateForLightingConditions(double brightness) {
    _pupilSize = (0.6 - (brightness * 0.4)).clamp(0.2, 0.6);
    notifyListeners();
  }

  void applyManualOverride({
    Emotion? emotion,
    EyeState? eyeState,
    double? eyeX,
    double? eyeY,
    double? pupilSize,
    double? eyeOpenness,
  }) {
    if (emotion != null) {
      setEmotion(emotion);
    }

    if (eyeState != null) {
      setEyeState(eyeState);
    }

    if (eyeX != null || eyeY != null) {
      setEyePosition(
        eyeX ?? _eyeX,
        eyeY ?? _eyeY,
      );
    }

    if (pupilSize != null) {
      _pupilSize = pupilSize.clamp(0.1, 0.8);
    }

    if (eyeOpenness != null) {
      _eyeOpenness = eyeOpenness.clamp(0.0, 1.0);
    }

    notifyListeners();
  }

  void resetToDefault() {
    _currentEmotion = Emotion.neutral;
    _eyeState = EyeState.open;
    _eyeX = 0.0;
    _eyeY = 0.0;
    _steeringAngle = 0.0;
    _isTracking = false;
    _trackedPersonId = null;
    _blinkProgress = 0.0;
    _isBlinking = false;
    _pupilSize = 0.3;
    _eyeOpenness = 1.0;
    _emotionIntensity = 0.0;

    notifyListeners();
  }

  void updateFromExternalState(Map<String, dynamic> state) {
    if (state.containsKey('emotion')) {
      final emotionStr = state['emotion'].toString().toLowerCase();
      switch (emotionStr) {
        case 'happy':
          setEmotion(Emotion.happy);
          break;
        case 'sad':
          setEmotion(Emotion.sad);
          break;
        case 'angry':
          setEmotion(Emotion.angry);
          break;
        case 'surprised':
          setEmotion(Emotion.surprised);
          break;
        case 'curious':
          setEmotion(Emotion.curious);
          break;
        case 'focused':
          setEmotion(Emotion.focused);
          break;
        case 'sleepy':
          setEmotion(Emotion.sleepy);
          break;
        case 'excited':
          setEmotion(Emotion.excited);
          break;
        case 'confused':
          setEmotion(Emotion.confused);
          break;
        default:
          setEmotion(Emotion.neutral);
      }
    }

    if (state.containsKey('eye_state')) {
      final eyeStateStr = state['eye_state'].toString().toLowerCase();
      switch (eyeStateStr) {
        case 'open':
          _eyeState = EyeState.open;
          break;
        case 'halfopen':
          _eyeState = EyeState.halfOpen;
          break;
        case 'closed':
          _eyeState = EyeState.closed;
          break;
        case 'blinking':
          _eyeState = EyeState.blinking;
          break;
        case 'looking':
          _eyeState = EyeState.looking;
          break;
        case 'tracking':
          _eyeState = EyeState.tracking;
          break;
        default:
          _eyeState = EyeState.open;
      }
    }

    if (state.containsKey('eye_x')) {
      _eyeX = (state['eye_x'] as num).toDouble().clamp(-1.0, 1.0);
    }

    if (state.containsKey('eye_y')) {
      _eyeY = (state['eye_y'] as num).toDouble().clamp(-1.0, 1.0);
    }

    if (state.containsKey('pupil_size')) {
      _pupilSize = (state['pupil_size'] as num).toDouble().clamp(0.1, 0.8);
    }

    if (state.containsKey('eye_openness')) {
      _eyeOpenness = (state['eye_openness'] as num).toDouble().clamp(0.0, 1.0);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _emotionTimer?.cancel();
    _trackingTimer?.cancel();
    _headPollTimer?.cancel();
    super.dispose();
  }
}
