import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../services/pi_backend_client.dart';
import 'dart:async';

class SensorData {
  final DateTime timestamp;
  final Map<String, dynamic> values;

  SensorData({required this.timestamp, required this.values});

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'values': values,
    };
  }
}

class SensorProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  // Barometer not available in current sensors_plus version
  // StreamSubscription<BarometerEvent>? _barometerSubscription;

  // Sensor data storage
  SensorData? _accelerometerData;
  SensorData? _gyroscopeData;
  SensorData? _magnetometerData;
  SensorData? _barometerData;
  Position? _locationData;
  BatteryInfo? _batteryInfo;
  DeviceInfo? _deviceInfo;
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;

  // Stream controllers for real-time data
  final StreamController<SensorData> _accelerometerController =
  StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _gyroscopeController =
  StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _magnetometerController =
  StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _barometerController =
  StreamController<SensorData>.broadcast();

  bool _isMonitoring = false;

  // Pi bridge config
  String? _piBaseUrl;
  bool _shareWithPi = false;
  Duration _shareInterval = const Duration(seconds: 1);
  Timer? _piShareTimer;
  PiBackendClient? _piClient;

  // Getters
  SensorData? get accelerometerData => _accelerometerData;
  SensorData? get gyroscopeData => _gyroscopeData;
  SensorData? get magnetometerData => _magnetometerData;
  SensorData? get barometerData => _barometerData;
  Position? get locationData => _locationData;
  BatteryInfo? get batteryInfo => _batteryInfo;
  DeviceInfo? get deviceInfo => _deviceInfo;
  ConnectivityResult get connectivityStatus => _connectivityStatus;
  bool get isMonitoring => _isMonitoring;

  String? get piBaseUrl => _piBaseUrl;
  bool get shareWithPi => _shareWithPi;
  Duration get shareInterval => _shareInterval;

  // Streams
  Stream<SensorData> get accelerometerStream => _accelerometerController.stream;
  Stream<SensorData> get gyroscopeStream => _gyroscopeController.stream;
  Stream<SensorData> get magnetometerStream => _magnetometerController.stream;
  Stream<SensorData> get barometerStream => _barometerController.stream;

  void setPiBaseUrl(String? baseUrl) {
    final trimmed = baseUrl?.trim();
    _piBaseUrl = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (_piBaseUrl != null) {
      _piClient = PiBackendClient(host: _piBaseUrl!, port: 8090);
    } else {
      _piClient = null;
    }
    _restartPiShareTimer();
  }

  void setShareWithPi(bool enabled, {Duration? interval}) {
    _shareWithPi = enabled;
    if (interval != null) {
      _shareInterval = interval;
    }
    _restartPiShareTimer();
    notifyListeners();
  }

  void _restartPiShareTimer() {
    _piShareTimer?.cancel();
    _piShareTimer = null;
    if (!_shareWithPi) return;
    if (_piClient == null) return;
    _piShareTimer = Timer.periodic(_shareInterval, (_) {
      _sendSnapshotToPi();
    });
  }

  Future<void> _sendSnapshotToPi() async {
    if (!_isMonitoring) return;
    final client = _piClient;
    if (client == null) return;
    final payload = _buildSensorsPayload();
    if (payload == null) return;
    try {
      await client.postSensors(payload);
    } catch (e) {
      _logger.w('Error sending sensors to Pi: $e');
    }
  }

  Map<String, dynamic>? _buildSensorsPayload() {
    final now = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> payload = {'ts': now};

    // Orientation: approximate with gyroscope if available.
    if (_gyroscopeData != null) {
      final v = _gyroscopeData!.values;
      payload['orientation'] = {
        'roll': v['x'],
        'pitch': v['y'],
        'yaw': v['z'],
      };
    }

    if (_accelerometerData != null) {
      final v = _accelerometerData!.values;
      payload['accel'] = {
        'x': v['x'],
        'y': v['y'],
        'z': v['z'],
      };
    }

    if (_locationData != null) {
      payload['gps'] = {
        'lat': _locationData!.latitude,
        'lon': _locationData!.longitude,
        'accuracy_m': _locationData!.accuracy,
      };
      if (_locationData!.altitude != 0.0) {
        payload['altitude_m'] = _locationData!.altitude;
      }
    }

    if (_batteryInfo != null) {
      payload['phone_battery'] = _batteryInfo!.level;
    }

    if (payload.keys.length <= 1) {
      // Only ts, nothing useful yet.
      return null;
    }

    return payload;
  }

  Future<void> initialize() async {
    _logger.i('Initializing sensor provider...');
    await _getDeviceInfo();
    await _getBatteryInfo();
    await _getLocation();
    await _getConnectivityStatus();
  }

  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      _deviceInfo = DeviceInfo(
        model: androidInfo.model,
        manufacturer: androidInfo.manufacturer,
        version: androidInfo.version.release,
        board: androidInfo.board,
        bootloader: androidInfo.bootloader,
        brand: androidInfo.brand,
        device: androidInfo.device,
        display: androidInfo.display,
        fingerprint: androidInfo.fingerprint,
        hardware: androidInfo.hardware,
        host: androidInfo.host,
        id: androidInfo.id,
        product: androidInfo.product,
        tags: androidInfo.tags,
        type: androidInfo.type,
        isPhysicalDevice: androidInfo.isPhysicalDevice,
      );
      notifyListeners();
    } catch (e) {
      _logger.e('Error getting device info: $e');
    }
  }

  Future<void> _getBatteryInfo() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      final status = await battery.batteryState;

      _batteryInfo = BatteryInfo(
        level: level,
        status: status.toString(),
      );
      notifyListeners();
    } catch (e) {
      _logger.e('Error getting battery info: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permissions are permanently denied');
        return;
      }

      _locationData = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      _logger.e('Error getting location: $e');
    }
  }

  Future<void> _getConnectivityStatus() async {
    try {
      final connectivity = Connectivity();
      _connectivityStatus = await connectivity.checkConnectivity();

      connectivity.onConnectivityChanged.listen((result) {
        _connectivityStatus = result;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      _logger.e('Error getting connectivity status: $e');
    }
  }

  void startMonitoring() {
    if (_isMonitoring) return;

    _logger.i('Starting sensor monitoring...');
    _isMonitoring = true;

    // Start accelerometer monitoring
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _accelerometerData = SensorData(
        timestamp: DateTime.now(),
        values: {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        },
      );
      _accelerometerController.add(_accelerometerData!);
      notifyListeners();
    });

    // Start gyroscope monitoring
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      _gyroscopeData = SensorData(
        timestamp: DateTime.now(),
        values: {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        },
      );
      _gyroscopeController.add(_gyroscopeData!);
      notifyListeners();
    });

    // Start magnetometer monitoring
    _magnetometerSubscription = magnetometerEvents.listen((event) {
      _magnetometerData = SensorData(
        timestamp: DateTime.now(),
        values: {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        },
      );
      _magnetometerController.add(_magnetometerData!);
      notifyListeners();
    });

    // Barometer not wired in current sensors_plus version
    notifyListeners();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;

    _logger.i('Stopping sensor monitoring...');
    _isMonitoring = false;

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    // _barometerSubscription?.cancel();

    notifyListeners();
  }

  Map<String, dynamic> getAllSensorData() {
    return {
      'accelerometer': _accelerometerData?.toJson(),
      'gyroscope': _gyroscopeData?.toJson(),
      'magnetometer': _magnetometerData?.toJson(),
      'barometer': _barometerData?.toJson(),
      'location': _locationData != null
          ? {
        'latitude': _locationData!.latitude,
        'longitude': _locationData!.longitude,
        'altitude': _locationData!.altitude,
        'accuracy': _locationData!.accuracy,
      }
          : null,
      'battery': _batteryInfo != null
          ? {
        'level': _batteryInfo!.level,
        'status': _batteryInfo!.status,
      }
          : null,
      'device': _deviceInfo != null
          ? {
        'model': _deviceInfo!.model,
        'manufacturer': _deviceInfo!.manufacturer,
        'version': _deviceInfo!.version,
      }
          : null,
      'connectivity': _connectivityStatus.toString(),
    };
  }

  @override
  void dispose() {
    stopMonitoring();
    _piShareTimer?.cancel();
    _accelerometerController.close();
    _gyroscopeController.close();
    _magnetometerController.close();
    _barometerController.close();
    super.dispose();
  }
}

class BatteryInfo {
  final int level;
  final String status;

  BatteryInfo({required this.level, required this.status});
}

class DeviceInfo {
  final String model;
  final String manufacturer;
  final String version;
  final String board;
  final String bootloader;
  final String brand;
  final String device;
  final String display;
  final String fingerprint;
  final String hardware;
  final String host;
  final String id;
  final String product;
  final String tags;
  final String type;
  final bool isPhysicalDevice;

  DeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.version,
    required this.board,
    required this.bootloader,
    required this.brand,
    required this.device,
    required this.display,
    required this.fingerprint,
    required this.hardware,
    required this.host,
    required this.id,
    required this.product,
    required this.tags,
    required this.type,
    required this.isPhysicalDevice,
  });
}
