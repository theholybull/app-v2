// lib/core/vision/vision_context.dart
//
// Lightweight vision data models used across providers and services.

/// Simple face description coming from the camera / ML pipeline.
class DetectedFaceInfo {
  final int? trackingId;

  /// Normalized bounding box coordinates in [0,1] relative to the frame.
  final double boundingBoxLeft;
  final double boundingBoxTop;
  final double boundingBoxRight;
  final double boundingBoxBottom;

  /// Optional probabilities from the detector.
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  const DetectedFaceInfo({
    this.trackingId,
    required this.boundingBoxLeft,
    required this.boundingBoxTop,
    required this.boundingBoxRight,
    required this.boundingBoxBottom,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });
}

/// Placeholder object description so we can extend later without breaking API.
class DetectedObjectInfo {
  final String label;
  final double confidence;

  const DetectedObjectInfo({
    required this.label,
    required this.confidence,
  });
}

/// Aggregated vision snapshot that other parts of the app can consume.
class VisionContext {
  /// Faces detected in the current frame.
  final List<DetectedFaceInfo> faces;

  /// Objects detected in the current frame (if/when we add them).
  final List<DetectedObjectInfo> objects;

  /// When this context was captured.
  final DateTime timestamp;

  /// Optional extra metadata (lighting, frame stats, etc).
  final Map<String, dynamic> metadata;

  /// Do NOT make this constructor const; it uses DateTime.now().
  VisionContext({
    List<DetectedFaceInfo>? faces,
    List<DetectedObjectInfo>? objects,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : faces = faces ?? const [],
        objects = objects ?? const [],
        timestamp = timestamp ?? DateTime.now().toUtc(),
        metadata = metadata ?? const {};

  /// Convenience: empty snapshot.
  factory VisionContext.empty() => VisionContext();

  /// True if we have at least one face.
  bool get hasFaces => faces.isNotEmpty;

  /// Number of faces in this snapshot.
  int get numFaces => faces.length;

  /// Convert to a simple map for logging / debugging.
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'faces': faces
          .map((f) => {
        'trackingId': f.trackingId,
        'bbox': [
          f.boundingBoxLeft,
          f.boundingBoxTop,
          f.boundingBoxRight,
          f.boundingBoxBottom,
        ],
        'smile': f.smilingProbability,
        'leftEye': f.leftEyeOpenProbability,
        'rightEye': f.rightEyeOpenProbability,
      })
          .toList(),
      'objects': objects
          .map((o) => {
        'label': o.label,
        'confidence': o.confidence,
      })
          .toList(),
      'metadata': metadata,
    };
  }

  @override
  String toString() =>
      'VisionContext(timestamp: $timestamp, faces: ${faces.length}, objects: ${objects.length}, metadata: $metadata)';
}

