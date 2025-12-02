import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PermissionService {
  static final Logger _logger = Logger();
  
  static Future<void> initialize() async {
    _logger.i('Initializing permission service...');
  }
  
  static Future<bool> requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.camera,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.phone,
      Permission.storage,
      Permission.sensors,
      Permission.systemAlertWindow,
    ];
    
    final Map<Permission, PermissionStatus> statuses = 
        await permissions.request();
    
    bool allGranted = true;
    for (final permission in permissions) {
      final status = statuses[permission] ?? PermissionStatus.denied;
      if (!status.isGranted) {
        _logger.w('Permission not granted: $permission');
        allGranted = false;
        
        // Show rationale for certain permissions
        if (status.isPermanentlyDenied) {
          await _showPermissionRationale(permission);
        }
      } else {
        _logger.i('Permission granted: $permission');
      }
    }
    
    return allGranted;
  }
  
  static Future<void> _showPermissionRationale(Permission permission) async {
    _logger.w('Permission $permission is permanently denied. Please enable in settings.');
    // In a real app, you would show a dialog explaining why the permission is needed
    // and open app settings
  }
  
  static Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }
  
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    final status = await permission.request();
    _logger.i('Permission $permission status: $status');
    return status;
  }
}