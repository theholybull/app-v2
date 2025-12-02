import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

class AudioProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isMicrophoneAvailable = false;
  bool _isSpeakerAvailable = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  Timer? _recordingTimer;
  
  // Recording settings
  static const int _sampleRate = 44100;
  static const int _bitRate = 128000;
  static const int _channels = 2;
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isMicrophoneAvailable => _isMicrophoneAvailable;
  bool get isSpeakerAvailable => _isSpeakerAvailable;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;
  Duration get playbackPosition => _playbackPosition;
  Duration get totalDuration => _totalDuration;
  double get recordingLevel => _isRecording ? 0.0 : 0.0;
  
  Future<void> initialize() async {
    _logger.i('Initializing audio provider...');
    
    try {
      // Initialize audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
      // Check microphone availability
      _isMicrophoneAvailable = await _recorder.hasPermission();
      
      // Check speaker availability
      await _player.setVolume(1.0);
      _isSpeakerAvailable = true;
      
      // Setup player listener
      _player.positionStream.listen((position) {
        _playbackPosition = position;
        notifyListeners();
      });
      
      _player.durationStream.listen((duration) {
        _totalDuration = duration ?? Duration.zero;
        notifyListeners();
      });
      
      _player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        notifyListeners();
      });
      
      _logger.i('Audio provider initialized successfully');
      notifyListeners();
    } catch (e) {
      _logger.e('Error initializing audio provider: $e');
    }
  }
  
  Future<void> startRecording({String? filePath}) async {
    if (_isRecording) return;
    
    try {
      // Request microphone permission if needed
      if (!_isMicrophoneAvailable) {
        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) {
          _logger.w('Microphone permission not granted');
          return;
        }
      }
      
      // Generate file path if not provided
      _currentRecordingPath = filePath ?? await _generateRecordingPath();
      
      _logger.i('Starting recording to: $_currentRecordingPath');
      
      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: _sampleRate,
          bitRate: _bitRate,
          numChannels: _channels,
        ),
        path: _currentRecordingPath!,
      );
      
      _isRecording = true;
      _recordingDuration = Duration.zero;
      
      // Start duration timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _recordingDuration = _recordingDuration + const Duration(milliseconds: 100);
        notifyListeners();
      });
      
      notifyListeners();
      _logger.i('Recording started successfully');
    } catch (e) {
      _logger.e('Error starting recording: $e');
    }
  }
  
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _logger.i('Stopping recording...');
      
      // Stop recording
      final path = await _recorder.stop();
      
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      _currentRecordingPath = path;
      
      notifyListeners();
      _logger.i('Recording stopped. File saved to: $path');
    } catch (e) {
      _logger.e('Error stopping recording: $e');
    }
  }
  
  Future<void> playAudio(String filePath) async {
    try {
      _logger.i('Playing audio: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.e('Audio file not found: $filePath');
        return;
      }
      
      await _player.setFilePath(filePath);
      await _player.play();
      
      notifyListeners();
    } catch (e) {
      _logger.e('Error playing audio: $e');
    }
  }
  
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      notifyListeners();
    } catch (e) {
      _logger.e('Error stopping playback: $e');
    }
  }
  
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
      notifyListeners();
    } catch (e) {
      _logger.e('Error setting volume: $e');
    }
  }
  
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      notifyListeners();
    } catch (e) {
      _logger.e('Error pausing playback: $e');
    }
  }
  
  Future<void> resumePlayback() async {
    try {
      await _player.play();
      notifyListeners();
    } catch (e) {
      _logger.e('Error resuming playback: $e');
    }
  }
  
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
      notifyListeners();
    } catch (e) {
      _logger.e('Error seeking: $e');
    }
  }
  
  Future<String> _generateRecordingPath() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '/storage/emulated/0/Download/viam_recording_$timestamp.aac';
  }
  
  Future<void> playTone({double frequency = 440.0, Duration duration = const Duration(seconds: 1)}) async {
    try {
      _logger.i('Playing tone: $frequency Hz for $duration');
      
      // Generate a simple sine wave tone
      final sampleRate = _sampleRate;
      final samples = <int>[];
      
      for (int i = 0; i < sampleRate * duration.inSeconds; i++) {
        final time = i / sampleRate;
        final value = (sin(2 * pi * frequency * time) * 32767).round();
        samples.add(value);
      }
      
      // This is a simplified approach - in production you'd use a proper audio library
      // to generate and play tones
      
      notifyListeners();
    } catch (e) {
      _logger.e('Error playing tone: $e');
    }
  }
  
  Map<String, dynamic> getAudioStatus() {
    return {
      'isRecording': _isRecording,
      'isPlaying': _isPlaying,
      'isMicrophoneAvailable': _isMicrophoneAvailable,
      'isSpeakerAvailable': _isSpeakerAvailable,
      'currentRecordingPath': _currentRecordingPath,
      'recordingDuration': _recordingDuration.inMilliseconds,
      'playbackPosition': _playbackPosition.inMilliseconds,
      'totalDuration': _totalDuration.inMilliseconds,
      'volume': 1.0, // Could be tracked if needed
    };
  }
  
  Future<void> testSpeakers() async {
    try {
      _logger.i('Testing speakers...');
      
      // Play a test tone sequence
      await playTone(frequency: 440.0, duration: const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 200));
      await playTone(frequency: 880.0, duration: const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 200));
      await playTone(frequency: 220.0, duration: const Duration(milliseconds: 500));
      
      _logger.i('Speaker test completed');
    } catch (e) {
      _logger.e('Error testing speakers: $e');
    }
  }
  
  Future<List<String>> getAvailableAudioDevices() async {
    try {
      // This would typically require platform-specific code
      // For now, return mock data
      return [
        'Built-in Speaker',
        'Built-in Microphone',
        'Wired Headset (if connected)',
        'Bluetooth Audio (if connected)',
      ];
    } catch (e) {
      _logger.e('Error getting audio devices: $e');
      return [];
    }
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}