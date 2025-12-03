import 'dart:async';

import '../models/head_state.dart';
import '../models/robot_event.dart';

/// Abstract connection to the Kilo Pi backend.
///
/// Concrete implementations:
///   - Bluetooth (primary)
///   - Wi-Fi HTTP (fallback / debug)
abstract class KiloLink {
  /// Human-readable label for diagnostics.
  String get label;

  /// Emits true when the link is considered "up".
  Stream<bool> get connectionStateStream;

  /// Emits events pushed from the Pi (safety, nav, etc.).
  Stream<RobotEvent> get eventStream;

  /// Get the current head state from the Pi.
  Future<HeadState> getHeadState();

  /// Push a new mode to the Pi (e.g. "idle", "follow", "dock").
  Future<void> setMode(String mode);

  /// Push a new emotion to the Pi (e.g. "happy", "annoyed").
  Future<void> setEmotion(String emotion);

  /// Optional eyes state override (e.g. "idle_blink", "thinking").
  Future<void> setEyesState(String eyesState) async {
    // Default is no-op; Bluetooth bridge can handle this if/when we add it.
  }

  /// Drive command in robot-centric units.
  ///
  /// For Ackermann, this may map to speed + steering.
  /// For skid steer, to left/right motor speeds.
  Future<void> sendDriveCommand({
    required double linearMetersPerSec,
    required double angularDegPerSec,
  });

  /// Clean up any resources.
  Future<void> dispose();
}
