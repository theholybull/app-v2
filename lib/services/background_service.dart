import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class BackgroundService {
  static const MethodChannel _channel = MethodChannel('viam_background_service');
  static final Logger _logger = Logger();
  
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod('getServiceStatus');
      return result['is_running'] ?? false;
    } catch (e) {
      _logger.e('Error checking service status: $e');
      return false;
    }
  }
  
  static Future<void> updateNotification(String title, String text) async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'title': title,
        'text': text,
      });
    } catch (e) {
      _logger.e('Error updating notification: $e');
    }
  }
  
  static void initializeServiceHandlers({
    Function(Map<String, dynamic>)? onUsbAttached,
    Function(Map<String, dynamic>)? onUsbDetached,
    Function(Map<String, dynamic>)? onAutoStart,
  }) {
    _channel.setMethodCallHandler((call) async {
      _logger.i('Background service method call: ${call.method}');
      
      switch (call.method) {
        case 'usbAttached':
          final arguments = Map<String, dynamic>.from(call.arguments);
          onUsbAttached?.call(arguments);
          break;
        case 'usbDetached':
          final arguments = Map<String, dynamic>.from(call.arguments);
          onUsbDetached?.call(arguments);
          break;
        case 'autoStart':
          final arguments = Map<String, dynamic>.from(call.arguments);
          onAutoStart?.call(arguments);
          break;
        default:
          _logger.w('Unknown method call: ${call.method}');
      }
    });
  }
}