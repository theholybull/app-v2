import 'dart:async';

import 'package:flutter/foundation.dart';

import 'vision_context.dart';

/// Central stream of "what the front camera currently sees".
///
/// This is fed by whichever layer is running face/object detection (currently
/// your FaceDetectionProvider using google_ml_kit).
class VisionService extends ChangeNotifier {
  VisionService();

  final StreamController<VisionContext> _contextController =
  StreamController<VisionContext>.broadcast();

  VisionContext _latest = const VisionContext(faces: [], objects: []);

  /// Latest fused context (faces + objects).
  VisionContext get latest => _latest;

  /// Stream of updates for consumers (personality, UI overlays, etc.).
  Stream<VisionContext> get stream => _contextController.stream;

  bool get hasFaces => _latest.hasFaces;
  int get numFaces => _latest.numFaces;

  void updateContext(VisionContext ctx) {
    _latest = ctx;
    _contextController.add(ctx);
    notifyListeners();
  }

  @override
  void dispose() {
    _contextController.close();
    super.dispose();
  }
}
