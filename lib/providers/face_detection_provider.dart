import 'dart:async';
import 'dart:io';
import 'dart:math' show Point;
import 'dart:ui' show Rect, Offset;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:logger/logger.dart';

// Adjust these imports if your folder layout differs.
import '../core/vision/vision_service.dart';
import '../core/vision/vision_context.dart';

class DetectedFace {
  final String id;
  final Rect boundingBox;
  final Point<double> rotationAngle;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final DateTime timestamp;

  DetectedFace({
    required this.id,
    required this.boundingBox,
    required this.rotationAngle,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bounding_box': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'rotation_angle': {
        'x': rotationAngle.x,
        'y': rotationAngle.y,
      },
      'smiling_probability': smilingProbability,
      'left_eye_open_probability': leftEyeOpenProbability,
      'right_eye_open_probability': rightEyeOpenProbability,
      'head_euler_angle_y': headEulerAngleY,
      'head_euler_angle_z': headEulerAngleZ,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class FaceDetectionProvider extends ChangeNotifier {
  FaceDetectionProvider({VisionService? visionService})
      : _visionService = visionService;

  final Logger _logger = Logger();

  /// Optional shared VisionService so personality/avatars can react to faces.
  final VisionService? _visionService;

  FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  List<DetectedFace> _detectedFaces = [];
  String? _trackedFaceId;
  bool _isDetecting = false;
  bool _isInitialized = false;
  bool _isProcessingFrame = false;
  CameraController? _cameraController;
  Timer? _detectionTimer;

  // Face tracking parameters
  int _nextFaceId = 1;
  final Map<String, DateTime> _lastSeen = {};
  static const Duration _faceTimeout = Duration(seconds: 5);

  // Detection settings
  double _detectionConfidence = 0.7;
  bool _enableSmileDetection = true;
  bool _enableEyeTracking = true;
  bool _enableHeadPose = true;

  // Getters
  List<DetectedFace> get detectedFaces => List.unmodifiable(_detectedFaces);
  String? get trackedFaceId => _trackedFaceId;
  bool get isDetecting => _isDetecting;
  bool get isInitialized => _isInitialized;
  double get detectionConfidence => _detectionConfidence;
  bool get enableSmileDetection => _enableSmileDetection;
  bool get enableEyeTracking => _enableEyeTracking;
  bool get enableHeadPose => _enableHeadPose;

  Future<void> initialize() async {
    _logger.i('Initializing face detection provider...');

    try {
      await _faceDetector.close();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: _enableSmileDetection,
          enableLandmarks: _enableEyeTracking,
          enableContours: true,
          enableTracking: true,
          minFaceSize: 0.1,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      _isInitialized = true;
      _logger.i('Face detection initialized successfully');
      notifyListeners();

      // If camera was already set, kick detection back on.
      if (_cameraController != null && !_isDetecting) {
        startDetection();
      }
    } catch (e) {
      _logger.e('Error initializing face detection: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  void setCameraController(CameraController? controller) {
    _cameraController = controller;

    if (controller != null && _isInitialized && !_isDetecting) {
      startDetection();
    } else if (controller == null) {
      stopDetection();
    }
  }

  Future<void> startDetection() async {
    if (_isDetecting || _cameraController == null || !_isInitialized) return;

    if (!_cameraController!.value.isInitialized) {
      _logger.w('CameraController is not initialized; cannot start detection.');
      return;
    }

    _logger.i('Starting face detection...');
    _isDetecting = true;
    notifyListeners();

    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 250),
          (_) => _detectFaces(),
    );
  }

  Future<void> stopDetection() async {
    _logger.i('Stopping face detection...');
    _isDetecting = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;
    notifyListeners();
  }

  Future<void> _detectFaces() async {
    if (!_isDetecting || _cameraController == null) return;
    if (_isProcessingFrame) return; // avoid overlapping work

    _isProcessingFrame = true;
    try {
      // Take a still frame. This is heavier than an image stream but simpler
      // and more reliable as a starting point.
      final image = await _cameraController!.takePicture();

      // Convert to InputImage for ML Kit
      final inputImage = _convertImageToInputImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      // Run ML Kit
      final faces = await _faceDetector.processImage(inputImage);

      // Process detected faces → internal list + VisionService
      await _processDetectedFaces(faces);

      // Clean up old faces
      _cleanupOldFaces();

      // Clean up temporary image file
      try {
        final file = File(image.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        _logger.w('Failed to delete temp image: $e');
      }
    } catch (e) {
      _logger.e('Error detecting faces: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _convertImageToInputImage(XFile imageFile) {
    try {
      // ML Kit will handle EXIF orientation when using fromFilePath.
      return InputImage.fromFilePath(imageFile.path);
    } catch (e) {
      _logger.e('Error converting image to InputImage: $e');
      return null;
    }
  }

  Future<void> _processDetectedFaces(List<Face> faces) async {
    final newFaces = <DetectedFace>[];
    final now = DateTime.now();

    for (final face in faces) {
      // Try to match with an existing face based on bounding box proximity.
      String? faceId = _findMatchingFace(face);

      if (faceId == null) {
        faceId = 'face_$_nextFaceId';
        _nextFaceId++;
      }

      _lastSeen[faceId] = now;

      final detectedFace = DetectedFace(
        id: faceId,
        boundingBox: face.boundingBox,
        rotationAngle: Point<double>(
          face.headEulerAngleY ?? 0.0,
          face.headEulerAngleZ ?? 0.0,
        ),
        smilingProbability: face.smilingProbability,
        leftEyeOpenProbability: face.leftEyeOpenProbability,
        rightEyeOpenProbability: face.rightEyeOpenProbability,
        headEulerAngleY: face.headEulerAngleY,
        headEulerAngleZ: face.headEulerAngleZ,
        timestamp: now,
      );

      // Optionally respect detectionConfidence by requiring some signal.
      if (_enableSmileDetection && detectedFace.smilingProbability != null) {
        if (detectedFace.smilingProbability! < _detectionConfidence) {
          // Low-confidence smile; still keep the face, just don't treat it as "smiling".
        }
      }

      newFaces.add(detectedFace);

      // Auto-track the first face if nothing is tracked.
      if (_trackedFaceId == null) {
        _trackedFaceId = faceId;
        _logger.i('Started tracking face: $faceId');
      }
    }

    _detectedFaces = newFaces;
    notifyListeners();

    // Also update the global VisionContext if a VisionService is provided.
    if (_visionService != null) {
      final vcFaces = _detectedFaces
          .map(
            (f) => DetectedFaceInfo(
          trackingId: int.tryParse(f.id.replaceFirst('face_', '')),
          boundingBoxLeft: f.boundingBox.left,
          boundingBoxTop: f.boundingBox.top,
          boundingBoxRight: f.boundingBox.right,
          boundingBoxBottom: f.boundingBox.bottom,
          smilingProbability: f.smilingProbability,
          leftEyeOpenProbability: f.leftEyeOpenProbability,
          rightEyeOpenProbability: f.rightEyeOpenProbability,
        ),
      )
          .toList();

      final ctx = VisionContext(
        faces: vcFaces,
        objects: const [], // object detection comes later
      );

      _visionService!.updateContext(ctx);
    }
  }

  String? _findMatchingFace(Face newFace) {
    if (_detectedFaces.isEmpty) return null;

    String? bestMatch;
    double bestDistance = double.infinity;

    for (final existingFace in _detectedFaces) {
      final distance = _calculateBoxDistance(
        newFace.boundingBox,
        existingFace.boundingBox,
      );

      if (distance < bestDistance && distance < 100.0) {
        bestMatch = existingFace.id;
        bestDistance = distance;
      }
    }

    return bestMatch;
  }

  double _calculateBoxDistance(Rect box1, Rect box2) {
    final center1 = box1.center;
    final center2 = box2.center;
    return (center1 - center2).distance;
  }

  void _cleanupOldFaces() {
    final now = DateTime.now();
    final facesToRemove = <String>[];

    _lastSeen.forEach((faceId, lastSeen) {
      if (now.difference(lastSeen) > _faceTimeout) {
        facesToRemove.add(faceId);
      }
    });

    for (final faceId in facesToRemove) {
      _lastSeen.remove(faceId);
      _detectedFaces.removeWhere((face) => face.id == faceId);

      if (_trackedFaceId == faceId) {
        _trackedFaceId = null;
        _logger.i('Stopped tracking face: $faceId');
      }
    }

    if (facesToRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  void trackFace(String? faceId) {
    _trackedFaceId = faceId;
    _logger.i('Tracking face: $faceId');
    notifyListeners();
  }

  void untrackFace() {
    _trackedFaceId = null;
    _logger.i('Stopped tracking all faces');
    notifyListeners();
  }

  DetectedFace? getTrackedFace() {
    if (_trackedFaceId == null) return null;
    try {
      return _detectedFaces.firstWhere((face) => face.id == _trackedFaceId);
    } catch (_) {
      return null;
    }
  }

  Point<double>? getTrackedFaceCenter() {
    final trackedFace = getTrackedFace();
    if (trackedFace == null) return null;

    return Point<double>(
      trackedFace.boundingBox.center.dx,
      trackedFace.boundingBox.center.dy,
    );
  }

  Map<String, dynamic> getDetectionStatus() {
    return {
      'is_detecting': _isDetecting,
      'is_initialized': _isInitialized,
      'detected_faces_count': _detectedFaces.length,
      'tracked_face_id': _trackedFaceId,
      'detection_confidence': _detectionConfidence,
      'enable_smile_detection': _enableSmileDetection,
      'enable_eye_tracking': _enableEyeTracking,
      'enable_head_pose': _enableHeadPose,
      'faces': _detectedFaces.map((face) => face.toJson()).toList(),
    };
  }

  void updateSettings({
    double? detectionConfidence,
    bool? enableSmileDetection,
    bool? enableEyeTracking,
    bool? enableHeadPose,
  }) {
    if (detectionConfidence != null) {
      _detectionConfidence = detectionConfidence.clamp(0.1, 1.0);
    }
    if (enableSmileDetection != null) {
      _enableSmileDetection = enableSmileDetection;
    }
    if (enableEyeTracking != null) {
      _enableEyeTracking = enableEyeTracking;
    }
    if (enableHeadPose != null) {
      _enableHeadPose = enableHeadPose;
    }

    initialize();
  }

  @override
  void dispose() {
    stopDetection();
    _faceDetector.close();
    super.dispose();
  }
}
