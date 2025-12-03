// lib/providers/pi_connection_provider.dart
//
// Kilo Pi Connection Provider (Patched)
// Adds:
//   - mDNS discovery (kilo.local)
//   - Subnet scan fallback
//   - Cached IP reuse
//   - Non-blocking connect flow
//   - Zero impact on existing UI/logic
//
// This file is SAFE to overwrite your current provider with.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PiConnectionProvider extends ChangeNotifier {
  bool isConnected = false;
  bool isConnecting = false;

  String? _baseUrl;        // final discovered URL
  Timer? _pollTimer;

  static const String _cacheKey = 'kilo_cached_ip';
  static const int _port = 8090;

  // PUBLIC ---------------------------------------------------------------------------------------

  String? get baseUrl => _baseUrl;

  Future<void> initialize() async {
    if (isConnecting) return;

    isConnecting = true;
    notifyListeners();

    // 1. Try cached IP
    if (await _tryCachedIP()) {
      isConnecting = false;
      notifyListeners();
      return;
    }

    // 2. Try mDNS
    if (await _tryMDNS()) {
      isConnecting = false;
      notifyListeners();
      return;
    }

    // 3. Scan network
    if (await _scanSubnet()) {
      isConnecting = false;
      notifyListeners();
      return;
    }

    // 4. Failed — fallback to disconnected mode
    isConnected = false;
    isConnecting = false;
    notifyListeners();
  }

  // INTERNAL --------------------------------------------------------------------------------------

  Future<bool> _tryCachedIP() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedIp = prefs.getString(_cacheKey);
    if (cachedIp == null) return false;

    final url = 'http://$cachedIp:$_port';
    if (await _attemptPing('$url/health')) {
      _setConnected(url, cachedIp);
      return true;
    }

    return false;
  }

  Future<bool> _tryMDNS() async {
    const host = 'kilo.local';
    final url = 'http://$host:$_port';

    if (await _attemptPing('$url/health')) {
      _setConnected(url, host);
      return true;
    }

    return false;
  }

  Future<bool> _scanSubnet() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();

    if (ip == null || ip.isEmpty) return false;

    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    for (int i = 1; i < 255; i++) {
      final host = '$subnet.$i';
      final url = 'http://$host:$_port';

      if (await _attemptPing('$url/health')) {
        _setConnected(url, host);
        return true;
      }
    }

    return false;
  }

  Future<bool> _attemptPing(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await utf8.decodeStream(response);
        return body.contains('"service": "kilo-head-backend"');
      }
    } catch (_) {}
    return false;
  }

  void _setConnected(String fullUrl, String ipOrHost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, ipOrHost);

    _baseUrl = fullUrl;
    isConnected = true;
    isConnecting = false;

    notifyListeners();
  }

  // OPTIONAL --------------------------------------------------------------------------------------

  void clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
