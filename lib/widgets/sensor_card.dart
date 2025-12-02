import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return Column(
          children: [
            // Accelerometer
            _buildSensorRow(
              context,
              'Accelerometer',
              sensorProvider.accelerometerData?.values,
              Icons.speed,
              Colors.blue,
              sensorProvider.accelerometerData?.timestamp,
            ),
            const Divider(),
            
            // Gyroscope
            _buildSensorRow(
              context,
              'Gyroscope',
              sensorProvider.gyroscopeData?.values,
              Icons.rotate_right,
              Colors.green,
              sensorProvider.gyroscopeData?.timestamp,
            ),
            const Divider(),
            
            // Magnetometer
            _buildSensorRow(
              context,
              'Magnetometer',
              sensorProvider.magnetometerData?.values,
              Icons.explore,
              Colors.orange,
              sensorProvider.magnetometerData?.timestamp,
            ),
            const Divider(),
            
            // Barometer
            _buildSensorRow(
              context,
              'Barometer',
              sensorProvider.barometerData?.values,
              Icons.compress,
              Colors.purple,
              sensorProvider.barometerData?.timestamp,
            ),
            const Divider(),
            
            // Location
            if (sensorProvider.locationData != null)
              _buildLocationRow(
                context,
                sensorProvider.locationData!,
              ),
            
            // Battery
            if (sensorProvider.batteryInfo != null)
              _buildBatteryRow(
                context,
                sensorProvider.batteryInfo!,
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildSensorRow(
    BuildContext context,
    String title,
    Map<String, dynamic>? values,
    IconData icon,
    Color color,
    DateTime? timestamp,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (values != null)
                  Text(
                    _formatSensorValues(title, values),
                    style: const TextStyle(fontSize: 12),
                  ),
                if (timestamp != null)
                  Text(
                    'Updated: ${_formatTime(timestamp)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (values == null)
            const Text(
              'No data',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLocationRow(BuildContext context, dynamic locationData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lat: ${locationData.latitude.toStringAsFixed(6)}, '
                  'Lng: ${locationData.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Accuracy: ${locationData.accuracy.toStringAsFixed(1)}m',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBatteryRow(BuildContext context, dynamic batteryInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            batteryInfo.level > 20 ? Icons.battery_full : Icons.battery_alert,
            color: batteryInfo.level > 20 ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Battery',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${batteryInfo.level}% - ${batteryInfo.status}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatSensorValues(String sensorType, Map<String, dynamic> values) {
    switch (sensorType) {
      case 'Accelerometer':
      case 'Gyroscope':
      case 'Magnetometer':
        final x = (values['x'] as double?)?.toStringAsFixed(3) ?? '0.000';
        final y = (values['y'] as double?)?.toStringAsFixed(3) ?? '0.000';
        final z = (values['z'] as double?)?.toStringAsFixed(3) ?? '0.000';
        return 'X: $x, Y: $y, Z: $z';
      case 'Barometer':
        final pressure = (values['pressure'] as double?)?.toStringAsFixed(2) ?? '0.00';
        return 'Pressure: $pressure hPa';
      default:
        return values.toString();
    }
  }
  
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}