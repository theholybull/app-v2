// lib/core/vision/vision_context.dart
//
// Cleaned, fixed, Dart-3 compatible VisionContext.
// No const constructor. No illegal initializers.
// Safe defaults. Backward-compatible.
//

class VisionContext {
  /// Timestamp the frame/analysis was taken
  final DateTime timestamp;

  /// Arbitrary metadata your vision pipeline attaches
  final Map<String, dynamic> metadata;

  /// DO NOT make this constructor const.
  /// It cannot be const because timestamp defaults use DateTime.now().
  VisionContext({
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now().toUtc(),
        metadata = metadata ?? const {};

  /// Helper: clone with updated metadata
  VisionContext copyWith({
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return VisionContext(
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper: read metadata value with safe typing
  T? get<T>(String key) {
    final value = metadata[key];
    if (value is T) return value;
    return null;
  }

  /// Convert to map for logging/debugging
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// String formatting for debug prints
  @override
  String toString() {
    return 'VisionContext(timestamp: $timestamp, metadata: $metadata)';
  }
}
