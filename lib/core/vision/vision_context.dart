import 'package:flutter/foundation.dart';

@immutable
class DetectedFaceInfo {
  final int? trackingId;
  final double boundingBoxLeft;
  final double boundingBoxTop;
  final double boundingBoxRight;
  final double boundingBoxBottom;
  final double? smilingProbability; // 0..1
  final double? leftEyeOpenProbability; // 0..1
  final double? rightEyeOpenProbability; // 0..1;

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

  double get width => boundingBoxRight - boundingBoxLeft;
  double get height => boundingBoxBottom - boundingBoxTop;

  /// Rough heuristic for "is this face likely looking at us?"
  bool get isAttentive {
    final le = leftEyeOpenProbability;
    final re = rightEyeOpenProbability;
    if (le == null || re == null) return false;
    // Tunable threshold.
    return le > 0.4 && re > 0.4;
  }
}

@immutable
class DetectedObjectInfo {
  final String label;
  final double confidence; // 0..1
  final double boundingBoxLeft;
  final double boundingBoxTop;
  final double boundingBoxRight;
  final double boundingBoxBottom;

  const DetectedObjectInfo({
    required this.label,
    required this.confidence,
    required this.boundingBoxLeft,
    required this.boundingBoxTop,
    required this.boundingBoxRight,
    required this.boundingBoxBottom,
  });

  double get width => boundingBoxRight - boundingBoxLeft;
  double get height => boundingBoxBottom - boundingBoxTop;
}

@immutable
class VisionContext {
  final List<DetectedFaceInfo> faces;
  final List<DetectedObjectInfo> objects;
  final DateTime timestamp;

  const VisionContext({
    required this.faces,
    required this.objects,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  bool get hasFaces => faces.isNotEmpty;
  int get numFaces => faces.length;

  /// The "main" face the personality should care about.
  DetectedFaceInfo? get primaryFace {
    if (faces.isEmpty) return null;
    // Simple heuristic: largest by area.
    return faces.reduce((a, b) {
      final areaA = a.width * a.height;
      final areaB = b.width * b.height;
      return areaA >= areaB ? a : b;
    });
  }

  bool get isSomeoneSmiling {
    return faces.any((f) =>
    (f.smilingProbability ?? 0.0) > 0.6 &&
        (f.leftEyeOpenProbability ?? 0.0) > 0.2 &&
        (f.rightEyeOpenProbability ?? 0.0) > 0.2);
  }
}
