import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/pi_connection_provider.dart';

class NetworkConfigScreen extends StatefulWidget {
  const NetworkConfigScreen({Key? key}) : super(key: key);

  @override
  State<NetworkConfigScreen> createState() => _NetworkConfigScreenState();
}

class _NetworkConfigScreenState extends State<NetworkConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _piIpController = TextEditingController();
  final TextEditingController _phoneIpController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _autoConnect = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final piIp = prefs.getString('pi_ip_address') ?? '10.10.10.67';
    final phoneIp = prefs.getString('phone_ip_address') ?? '10.10.10.65';
    final viamPort = prefs.getString('viam_port') ?? '8090';
    final autoConnect = prefs.getBool('auto_connect') ?? true;

    setState(() {
      _piIpController.text = piIp;
      _phoneIpController.text = phoneIp;
      _portController.text = viamPort;
      _autoConnect = autoConnect;
      _loading = false;
    });
  }

  Future<void> _saveAndTest(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final piProvider =
    Provider.of<PiConnectionProvider>(context, listen: false);

    final piIp = _piIpController.text.trim();
    final phoneIp = _phoneIpController.text.trim();
    final portStr = _portController.text.trim();
    final port = int.tryParse(portStr) ?? 8090;

    setState(() {
      _loading = true;
    });

    try {
      // We still store phone_ip_address here (for reference).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_ip_address', phoneIp);

      // New unified config+reconnect.
      final ok = await piProvider.applyConfigAndReconnect(
        address: piIp,
        port: port,
        autoConnect: _autoConnect,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Connected to Pi at $piIp:$port'
                : 'Could not connect to Pi at $piIp:$port',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _piIpController.dispose();
    _phoneIpController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piProvider = Provider.of<PiConnectionProvider>(context);
    final status = piProvider.connectionStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Configuration'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Pi Connection',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _piIpController,
                decoration: const InputDecoration(
                  labelText: 'Pi Host / IP or URL',
                  hintText: 'e.g. 10.10.10.67 or http://10.10.10.67:8090/',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a Pi host or IP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Backend Port',
                  hintText: 'e.g. 8090',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a port';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Port must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Phone Settings (optional)',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneIpController,
                decoration: const InputDecoration(
                  labelText: 'Phone IP (for reference)',
                  hintText: 'Not required for Wi-Fi mode',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Auto-connect to Pi'),
                value: _autoConnect,
                onChanged: (value) {
                  setState(() {
                    _autoConnect = value;
                  });
                  piProvider.setAutoConnect(value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                _loading ? null : () => _saveAndTest(context),
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Save & Test Connection'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Current Status',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Connected: ${status.isConnected ? "Yes" : "No"}'),
              Text('Pi address: ${status.piAddress ?? "Unknown"}'),
              Text('Last ping: '
                  '${status.lastPing >= 0 ? "${status.lastPing} ms" : "N/A"}'),
              if (status.error != null && status.error!.isNotEmpty)
                Text(
                  'Last error: ${status.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
