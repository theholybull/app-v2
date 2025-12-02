import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' show Offset;

class CameraProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  
  CameraController? _frontCameraController;
  CameraController? _backCameraController;
  CameraController? _currentCameraController;
  
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isCapturing = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  
  String? _lastImagePath;
  String? _lastVideoPath;
  FlashMode _flashMode = FlashMode.auto;
  
  // Stream controllers for camera frames
  final StreamController<CameraImage> _frameStreamController = 
      StreamController<CameraImage>.broadcast();
  
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  
  // Getters
  List<CameraDescription> get cameras => _cameras;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isCapturing => _isCapturing;
  CameraController? get currentCameraController => _currentCameraController;
  CameraLensDirection get currentLensDirection => _currentLensDirection;
  String? get lastImagePath => _lastImagePath;
  String? get lastVideoPath => _lastVideoPath;
  FlashMode get flashMode => _flashMode;
  Duration get recordingDuration => _recordingDuration;
  Stream<CameraImage> get frameStream => _frameStreamController.stream;
  
  bool get hasFrontCamera => _cameras.any((camera) => 
      camera.lensDirection == CameraLensDirection.front);
  bool get hasBackCamera => _cameras.any((camera) => 
      camera.lensDirection == CameraLensDirection.back);
  
  Future<void> initialize() async {
    _logger.i('Initializing camera provider...');
    
    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _logger.w('No cameras found on device');
        notifyListeners();
        return;
      }
      
      _logger.i('Found ${_cameras.length} cameras:');
      for (final camera in _cameras) {
        _logger.i('  - ${camera.name} (${camera.lensDirection})');
      }
      
      // Initialize back camera by default
      await _initializeCamera(CameraLensDirection.back);
      
      _isInitialized = true;
      notifyListeners();
      _logger.i('Camera provider initialized successfully');
    } catch (e) {
      _logger.e('Error initializing camera provider: $e');
    }
  }
  
  Future<void> _initializeCamera(CameraLensDirection direction) async {
    try {
      // Dispose current controller if exists
      await _currentCameraController?.dispose();
      
      // Find camera with specified direction
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == direction,
        orElse: () => _cameras.first,
      );
      
      // Create new controller
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await controller.initialize();
      
      // Store controller
      if (direction == CameraLensDirection.front) {
        _frontCameraController = controller;
      } else {
        _backCameraController = controller;
      }
      
      _currentCameraController = controller;
      _currentLensDirection = direction;
      
      // Setup frame stream for image processing
      controller.startImageStream((image) {
        if (_frameStreamController.hasListener) {
          _frameStreamController.add(image);
        }
      });
      
      _logger.i('Camera initialized: ${camera.name} (${direction})');
      notifyListeners();
    } catch (e) {
      _logger.e('Error initializing camera ($direction): $e');
    }
  }
  
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    
    try {
      final newDirection = _currentLensDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      
      _logger.i('Switching camera to: $newDirection');
      await _initializeCamera(newDirection);
    } catch (e) {
      _logger.e('Error switching camera: $e');
    }
  }
  
  Future<String?> captureImage() async {
    if (_currentCameraController == null || !_currentCameraController!.value.isInitialized) {
      _logger.w('Camera not initialized for image capture');
      return null;
    }
    
    if (_isCapturing) return null;
    
    try {
      _isCapturing = true;
      notifyListeners();
      
      final XFile image = await _currentCameraController!.takePicture();
      _lastImagePath = image.path;
      
      _logger.i('Image captured: ${image.path}');
      notifyListeners();
      
      return image.path;
    } catch (e) {
      _logger.e('Error capturing image: $e');
      return null;
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }
  
  Future<String?> startVideoRecording() async {
    if (_currentCameraController == null || !_currentCameraController!.value.isInitialized) {
      _logger.w('Camera not initialized for video recording');
      return null;
    }
    
    if (_isRecording) return null;
    
    try {
      _isRecording = true;
      _recordingDuration = Duration.zero;
      notifyListeners();
      
      await _currentCameraController!.startVideoRecording();
      
      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        notifyListeners();
      });
      
      _logger.i('Video recording started');
      return null; // Path will be available when recording stops
    } catch (e) {
      _logger.e('Error starting video recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<String?> stopVideoRecording() async {
    if (!_isRecording || _currentCameraController == null) return null;
    
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      final XFile video = await _currentCameraController!.stopVideoRecording();
      _lastVideoPath = video.path;
      _isRecording = false;
      
      notifyListeners();
      _logger.i('Video recording stopped: ${video.path}');
      
      return video.path;
    } catch (e) {
      _logger.e('Error stopping video recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<void> setFlashMode(FlashMode mode) async {
    if (_currentCameraController == null) return;
    
    try {
      await _currentCameraController!.setFlashMode(mode);
      _flashMode = mode;
      notifyListeners();
      _logger.i('Flash mode set to: $mode');
    } catch (e) {
      _logger.e('Error setting flash mode: $e');
    }
  }
  
  Future<void> toggleFlash() async {
    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.off;
        break;
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.torch:
        newMode = FlashMode.auto;
        break;
    }
    
    await setFlashMode(newMode);
  }
  
  Future<void> setFocusPoint(Offset point) async {
    if (_currentCameraController == null) return;
    
    try {
      await _currentCameraController!.setFocusPoint(point);
      _logger.i('Focus point set to: $point');
    } catch (e) {
      _logger.e('Error setting focus point: $e');
    }
  }
  
  Future<void> setExposurePoint(Offset point) async {
    if (_currentCameraController == null) return;
    
    try {
      await _currentCameraController!.setExposurePoint(point);
      _logger.i('Exposure point set to: $point');
    } catch (e) {
      _logger.e('Error setting exposure point: $e');
    }
  }
  
  Future<void> setZoomLevel(double zoom) async {
    if (_currentCameraController == null) return;
    
    try {
      final maxZoom = await _currentCameraController!.getMaxZoomLevel();
      final minZoom = await _currentCameraController!.getMinZoomLevel();
      
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _currentCameraController!.setZoomLevel(clampedZoom);
      
      _logger.i('Zoom level set to: $clampedZoom');
    } catch (e) {
      _logger.e('Error setting zoom level: $e');
    }
  }
  
  Map<String, dynamic> getCameraStatus() {
    return {
      'isInitialized': _isInitialized,
      'isRecording': _isRecording,
      'isCapturing': _isCapturing,
      'currentLensDirection': _currentLensDirection.toString(),
      'lastImagePath': _lastImagePath,
      'lastVideoPath': _lastVideoPath,
      'flashMode': _flashMode.toString(),
      'recordingDuration': _recordingDuration.inMilliseconds,
      'cameras': _cameras.map((camera) => {
        'name': camera.name,
        'lensDirection': camera.lensDirection.toString(),
        'sensorOrientation': camera.sensorOrientation,
      }).toList(),
    };
  }
  
  Future<void> testCameras() async {
    if (!_isInitialized) return;
    
    try {
      _logger.i('Testing cameras...');
      
      // Test capture on current camera
      await captureImage();
      
      // Switch camera and test again if available
      if (hasFrontCamera && hasBackCamera) {
        await switchCamera();
        await Future.delayed(const Duration(seconds: 1));
        await captureImage();
        await switchCamera(); // Switch back
      }
      
      _logger.i('Camera test completed');
    } catch (e) {
      _logger.e('Error testing cameras: $e');
    }
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _frameStreamController.close();
    _frontCameraController?.dispose();
    _backCameraController?.dispose();
    super.dispose();
  }
}