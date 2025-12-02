import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';

class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_android, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Device Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (sensorProvider.deviceInfo != null)
                  _buildDeviceInfo(sensorProvider.deviceInfo!),
                
                const SizedBox(height: 12),
                
                // Connectivity Status
                _buildConnectivityInfo(sensorProvider.connectivityStatus),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDeviceInfo(dynamic deviceInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Model', deviceInfo.model),
          _buildInfoRow('Manufacturer', deviceInfo.manufacturer),
          _buildInfoRow('Android Version', deviceInfo.version),
          _buildInfoRow('Device', deviceInfo.device),
          _buildInfoRow('Hardware', deviceInfo.hardware),
          _buildInfoRow('Physical Device', deviceInfo.isPhysicalDevice ? 'Yes' : 'No'),
        ],
      ),
    );
  }
  
  Widget _buildConnectivityInfo(List connectivityStatus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue[700], size: 16),
              const SizedBox(width: 4),
              Text(
                'Connectivity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...connectivityStatus.map((status) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                Icon(
                  _getConnectivityIcon(status.toString()),
                  size: 16,
                  color: _getConnectivityColor(status.toString()),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatConnectivityStatus(status.toString()),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getConnectivityIcon(String status) {
    switch (status.toLowerCase()) {
      case 'connectivityresult.wifi':
        return Icons.wifi;
      case 'connectivityresult.mobile':
        return Icons.signal_cellular_alt;
      case 'connectivityresult.ethernet':
        return Icons.settings_ethernet;
      case 'connectivityresult.bluetooth':
        return Icons.bluetooth;
      case 'connectivityresult.none':
        return Icons.signal_wifi_off;
      default:
        return Icons.device_hub;
    }
  }
  
  Color _getConnectivityColor(String status) {
    switch (status.toLowerCase()) {
      case 'connectivityresult.wifi':
      case 'connectivityresult.mobile':
      case 'connectivityresult.ethernet':
        return Colors.green;
      case 'connectivityresult.bluetooth':
        return Colors.blue;
      case 'connectivityresult.none':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _formatConnectivityStatus(String status) {
    switch (status.toLowerCase()) {
      case 'connectivityresult.wifi':
        return 'Wi-Fi Connected';
      case 'connectivityresult.mobile':
        return 'Mobile Data Connected';
      case 'connectivityresult.ethernet':
        return 'Ethernet Connected';
      case 'connectivityresult.bluetooth':
        return 'Bluetooth Available';
      case 'connectivityresult.none':
        return 'No Internet Connection';
      default:
        return status.replaceAll('connectivityresult.', '').toUpperCase();
    }
  }
}