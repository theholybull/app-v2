// lib/core/vision/vision_service.dart
//
// Central place to track the latest VisionContext and broadcast it as a stream.

import 'dart:async';

import 'vision_context.dart';

class VisionService {
  VisionService();

  /// Latest snapshot coming from whatever vision pipeline is active.
  VisionContext _latest = VisionContext.empty();

  final StreamController<VisionContext> _contextController =
  StreamController<VisionContext>.broadcast();

  /// Stream of context updates.
  Stream<VisionContext> get contextStream => _contextController.stream;

  /// Current snapshot.
  VisionContext get latest => _latest;

  /// Convenience: whether we currently see at least one face.
  bool get hasFaces => _latest.hasFaces;

  /// Convenience: number of faces in the latest snapshot.
  int get numFaces => _latest.numFaces;

  /// New API: called by providers when they have a new vision snapshot.
  void updateFromVision(VisionContext ctx) {
    _latest = ctx;
    _contextController.add(ctx);
  }

  /// Back-compat shim for existing callers (e.g. FaceDetectionProvider).
  /// This simply forwards to [updateFromVision].
  void updateContext(VisionContext ctx) {
    updateFromVision(ctx);
  }

  /// For manual overrides / testing if needed.
  void reset() {
    _latest = VisionContext.empty();
    _contextController.add(_latest);
  }

  void dispose() {
    _contextController.close();
  }
}

