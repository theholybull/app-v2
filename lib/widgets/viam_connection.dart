import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/viam_provider.dart';

class ViamConnectionDialog extends StatefulWidget {
  const ViamConnectionDialog({super.key});

  @override
  State<ViamConnectionDialog> createState() => _ViamConnectionDialogState();
}

class _ViamConnectionDialogState extends State<ViamConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _robotAddressController = TextEditingController();
  bool _autoReconnect = true;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  void _loadCurrentSettings() {
    final viamProvider = Provider.of<ViamProvider>(context, listen: false);
    _apiKeyIdController.text = viamProvider.apiKeyId;
    _apiKeyController.text = viamProvider.apiKey;
    _robotAddressController.text = viamProvider.robotAddress;
    _autoReconnect = viamProvider.autoReconnect;
  }
  
  @override
  void dispose() {
    _apiKeyIdController.dispose();
    _apiKeyController.dispose();
    _robotAddressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ViamProvider>(
      builder: (context, viamProvider, child) {
        return AlertDialog(
          title: const Text('Viam Connection Settings'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Connection Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: viamProvider.isConnected ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: viamProvider.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          viamProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: viamProvider.isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viamProvider.isConnected 
                              ? 'Connected to ${viamProvider.robotAddress}'
                              : 'Not connected',
                            style: TextStyle(
                              color: viamProvider.isConnected ? Colors.green[800] : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // API Key ID
                  TextFormField(
                    controller: _apiKeyIdController,
                    decoration: const InputDecoration(
                      labelText: 'API Key ID',
                      hintText: 'Enter your Viam API Key ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter API Key ID';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // API Key
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your Viam API Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter API Key';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Robot Address
                  TextFormField(
                    controller: _robotAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Robot Address',
                      hintText: 'e.g., robot-name.example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter robot address';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Auto Reconnect
                  SwitchListTile(
                    title: const Text('Auto Reconnect'),
                    subtitle: const Text('Automatically reconnect if connection is lost'),
                    value: _autoReconnect,
                    onChanged: (value) {
                      setState(() {
                        _autoReconnect = value;
                      });
                      viamProvider.setAutoReconnect(value);
                    },
                  ),
                  
                  // Connection Info
                  if (viamProvider.connectionStatus.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection Error:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            viamProvider.connectionStatus.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  
                  // Resources Info
                  if (viamProvider.isConnected && viamProvider.viamResources.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Resources:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(height: 4),
                          ...viamProvider.viamResources.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              '${entry.key}: ${entry.value['type']} - ${entry.value['name']}',
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            // Disconnect Button
            if (viamProvider.isConnected)
              TextButton.icon(
                onPressed: () async {
                  await viamProvider.disconnect();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            
            // Connect Button
            ElevatedButton.icon(
              onPressed: viamProvider.isConnected ? null : _connect,
              icon: viamProvider.isConnected 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.connect_without_contact),
              label: Text(viamProvider.isConnected ? 'Connecting...' : 'Connect'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    
    final viamProvider = Provider.of<ViamProvider>(context, listen: false);
    
    await viamProvider.initialize(
      apiKeyId: _apiKeyIdController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      robotAddress: _robotAddressController.text.trim(),
    );
    
    if (viamProvider.isConnected) {
      Navigator.of(context).pop();
    }
  }
}

class ViamStatusWidget extends StatelessWidget {
  const ViamStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ViamProvider>(
      builder: (context, viamProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      viamProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: viamProvider.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Viam Connection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  viamProvider.isConnected 
                    ? 'Connected to ${viamProvider.robotAddress}'
                    : 'Not connected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (viamProvider.connectionStatus.error != null)
                  Text(
                    'Error: ${viamProvider.connectionStatus.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                if (viamProvider.isConnected)
                  ElevatedButton.icon(
                    onPressed: () => _showConnectionDialog(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ViamConnectionDialog(),
    );
  }
}