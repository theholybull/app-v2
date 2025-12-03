import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Simple model of current Pi connection status.
class PiConnectionStatus {
  final bool isConnected;
  final String? piAddress;
  final String? connectionType; // e.g. "Wi-Fi"
  final String? error;
  final int lastPing; // ms, -1 if unknown

  const PiConnectionStatus({
    required this.isConnected,
    this.piAddress,
    this.connectionType,
    this.error,
    required this.lastPing,
  });

  PiConnectionStatus copyWith({
    bool? isConnected,
    String? piAddress,
    String? connectionType,
    String? error,
    int? lastPing,
  }) {
    return PiConnectionStatus(
      isConnected: isConnected ?? this.isConnected,
      piAddress: piAddress ?? this.piAddress,
      connectionType: connectionType ?? this.connectionType,
      error: error ?? this.error,
      lastPing: lastPing ?? this.lastPing,
    );
  }
}

class PiConnectionProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  // Current status exposed to the UI.
  PiConnectionStatus _connectionStatus =
  const PiConnectionStatus(isConnected: false, lastPing: -1);
  bool _autoConnect = true;
  bool _isScanning = false;

  // Config
  String _piAddress = '10.10.10.67'; // default; overridden by prefs
  int _backendPort = 8090; // default backend port

  // Timers
  Timer? _pingTimer;

  // Expose current configured address/port so other parts of the app
  // (like backend clients) can use the same values.
  String get configuredPiAddress => _piAddress;
  int get configuredBackendPort => _backendPort;

  // Public getters used around the app
  PiConnectionStatus get connectionStatus => _connectionStatus;
  bool get autoConnect => _autoConnect;
  bool get isScanning => _isScanning;

  PiConnectionProvider() {
    _loadConfiguration();
  }

  /// Called from HomeScreen.initState().
  Future<void> initialize() async {
    await _loadConfiguration();
    _startMonitoring();
  }

  // -------- Configuration --------

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _piAddress = prefs.getString('pi_ip_address') ?? _piAddress;
      _backendPort =
          int.tryParse(prefs.getString('viam_port') ?? '') ?? _backendPort;
      _autoConnect = prefs.getBool('auto_connect') ?? _autoConnect;

      _logger.i(
          'Loaded config: pi=$_piAddress, port=$_backendPort, autoConnect=$_autoConnect');
    } catch (e) {
      _logger.e('Error loading Pi connection config: $e');
    }

    notifyListeners();
  }

  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pi_ip_address', _piAddress);
      await prefs.setString('viam_port', _backendPort.toString());
      await prefs.setBool('auto_connect', _autoConnect);

      _logger.i(
          'Saved config: pi=$_piAddress, port=$_backendPort, autoConnect=$_autoConnect');
    } catch (e) {
      _logger.e('Error saving Pi connection config: $e');
    }
  }

  /// New unified entry point when settings change.
  ///
  /// - Updates IP/port/autoconnect
  /// - Saves config
  /// - Resets status
  /// - Restarts monitoring
  /// - Immediately attempts an HTTP connection
  Future<bool> applyConfigAndReconnect({
    required String address,
    required int port,
    required bool autoConnect,
  }) async {
    _pingTimer?.cancel();

    _piAddress = address.trim();
    _backendPort = port;
    _autoConnect = autoConnect;

    await _saveConfiguration();

    // Reset status so UI doesn’t show stale info.
    _updateStatus(
      isConnected: false,
      piAddress: _piAddress,
      connectionType: null,
      error: null,
      lastPing: -1,
    );

    _startMonitoring();

    // Always attempt a one-shot connect for "Save & Test".
    return _attemptConnect(_piAddress);
  }

  /// Backwards-compatible: manual connect call uses the same logic
  /// but preserves current autoConnect flag.
  Future<bool> connectToPi(String address, {int? port}) async {
    final p = port ?? _backendPort;
    return applyConfigAndReconnect(
      address: address,
      port: p,
      autoConnect: _autoConnect,
    );
  }

  /// External toggle for auto-connect (settings / UI switch).
  void setAutoConnect(bool enabled) {
    _autoConnect = enabled;
    _saveConfiguration();
    _startMonitoring();
    notifyListeners();
  }

  // -------- Monitoring & Scanning --------

  void _startMonitoring() {
    _pingTimer?.cancel();

    if (!_autoConnect) {
      return;
    }

    // Ping every 10 seconds as a sanity check.
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_connectionStatus.piAddress != null) {
        await _attemptPing(_connectionStatus.piAddress!);
      } else {
        await scanForPi();
      }
    });
  }

  /// "Scan" in v2 is really just "try the configured address".
  Future<void> scanForPi() async {
    if (_isScanning) return;

    _isScanning = true;
    notifyListeners();

    try {
      _logger.i('Scanning for Pi at $_piAddress:$_backendPort');
      final ok = await _attemptConnect(_piAddress);
      if (!ok && _connectionStatus.error == null) {
        _updateStatus(
          isConnected: false,
          error: 'Could not reach Pi at $_piAddress:$_backendPort',
        );
      }
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _logger.i('Disconnect requested by user');
    _pingTimer?.cancel();
    _updateStatus(
      isConnected: false,
      piAddress: _connectionStatus.piAddress,
      connectionType: null,
      error: 'Disconnected',
      lastPing: -1,
    );
    notifyListeners();
  }

  // -------- Internal helpers (HTTP-based) --------

  Uri _buildUri(String address) {
    final trimmed = address.trim();

    // If user entered a full URL (with scheme), trust it and ignore backendPort.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        _logger.d('Using full URL from config: $uri');
        return uri;
      } catch (e) {
        _logger
            .w('Invalid full URL "$trimmed", falling back to host:port: $e');
      }
    }

    final uri = Uri.parse('http://$trimmed:$_backendPort/');
    _logger.d('Built URI from host+port: $uri');
    return uri;
  }

  Future<bool> _attemptConnect(String address) async {
    try {
      final uri = _buildUri(address);
      _logger.i('Attempting HTTP connect to $uri');
      final sw = Stopwatch()..start();

      final response =
      await http.get(uri).timeout(const Duration(seconds: 5));

      sw.stop();

      final pingMs = sw.elapsedMilliseconds;
      _updateStatus(
        isConnected: true,
        piAddress: address,
        connectionType: 'Wi-Fi',
        error: null,
        lastPing: pingMs,
      );

      _logger.i(
          'HTTP connect OK to $uri (status ${response.statusCode}) in ${pingMs}ms');
      return true;
    } catch (e) {
      final uri = _buildUri(address);
      _logger.w('Failed HTTP connect to $uri: $e');
      _updateStatus(
        isConnected: false,
        piAddress: address,
        connectionType: null,
        error: e.toString(),
        lastPing: -1,
      );
      return false;
    }
  }

  Future<void> _attemptPing(String address) async {
    try {
      final uri = _buildUri(address);
      final sw = Stopwatch()..start();

      final response =
      await http.get(uri).timeout(const Duration(seconds: 3));

      sw.stop();
      final pingMs = sw.elapsedMilliseconds;

      _updateStatus(
        isConnected: true,
        piAddress: address,
        connectionType: 'Wi-Fi',
        error: null,
        lastPing: pingMs,
      );
      _logger.d(
          'Ping HTTP to $uri = ${pingMs}ms (status ${response.statusCode})');
    } catch (e) {
      final uri = _buildUri(address);
      _logger.w('Ping HTTP failed to $uri: $e');
      _updateStatus(
        isConnected: false,
        piAddress: address,
        connectionType: null,
        error: e.toString(),
        lastPing: -1,
      );
    }
  }

  void _updateStatus({
    required bool isConnected,
    String? piAddress,
    String? connectionType,
    String? error,
    int? lastPing,
  }) {
    _connectionStatus = _connectionStatus.copyWith(
      isConnected: isConnected,
      piAddress: piAddress,
      connectionType: connectionType,
      error: error,
      lastPing: lastPing,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}
