import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pi_connection_provider.dart';

class PiConnectionWidget extends StatelessWidget {
  const PiConnectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PiConnectionProvider>(
      builder: (context, piProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      piProvider.connectionStatus.isConnected 
                        ? Icons.usb 
                        : Icons.usb_off,
                      color: piProvider.connectionStatus.isConnected 
                        ? Colors.green 
                        : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pi Connection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Switch(
                      value: piProvider.autoConnect,
                      onChanged: piProvider.setAutoConnect,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Connection status
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: piProvider.connectionStatus.isConnected 
                          ? Colors.green 
                          : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        piProvider.connectionStatus.isConnected 
                          ? 'Connected to ${piProvider.connectionStatus.piAddress}'
                          : piProvider.connectionStatus.error ?? 'Not connected',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (piProvider.connectionStatus.lastPing > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${piProvider.connectionStatus.lastPing}ms',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Connection type and details
                if (piProvider.connectionStatus.connectionType != null)
                  Text(
                    'Type: ${piProvider.connectionStatus.connectionType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: piProvider.isScanning ? null : () {
                          piProvider.scanForPi();
                        },
                        icon: piProvider.isScanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                        label: Text(piProvider.isScanning ? 'Scanning...' : 'Scan for Pi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: piProvider.connectionStatus.isConnected 
                            ? Colors.green 
                            : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (piProvider.connectionStatus.isConnected)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => piProvider.disconnect(),
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Manual connection input
                if (!piProvider.connectionStatus.isConnected)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Pi IP Address',
                            hintText: '10.10.10.1',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            // Update pi address if needed
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // Manual connection logic
                          final controller = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Connect to Pi'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Pi IP Address',
                                  hintText: '10.10.10.67',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final address = controller.text.trim();
                                    if (address.isNotEmpty) {
                                      piProvider.connectToPi(address);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text('Connect'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.link),
                        tooltip: 'Manual Connect',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}