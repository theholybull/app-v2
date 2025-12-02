import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pi_connection_provider.dart';
import '../services/pi_backend_client.dart';

class PersonalityPanel extends StatefulWidget {
  const PersonalityPanel({Key? key}) : super(key: key);

  @override
  State<PersonalityPanel> createState() => _PersonalityPanelState();
}

class _PersonalityPanelState extends State<PersonalityPanel> {
  bool _loadingState = false;
  PiState? _piState;
  String? _error;

  PiBackendClient _buildClient(PiConnectionProvider piProvider) {
    final status = piProvider.connectionStatus;
    final host = status.piAddress ?? piProvider.configuredPiAddress;
    final port = piProvider.configuredBackendPort;
    return PiBackendClient(host: host, port: port);
  }

  Future<void> _refreshState(PiConnectionProvider piProvider) async {
    setState(() {
      _loadingState = true;
      _error = null;
    });

    try {
      final client = _buildClient(piProvider);
      final state = await client.getState();
      setState(() {
        _piState = state;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingState = false;
      });
    }
  }

  Future<void> _setEmotion(
      PiConnectionProvider piProvider,
      String emotion,
      ) async {
    setState(() {
      _error = null;
    });
    try {
      final client = _buildClient(piProvider);
      await client.setEmotion(emotion);
      await _refreshState(piProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emotion set to $emotion')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set emotion: $e')),
      );
    }
  }

  Future<void> _setMode(
      PiConnectionProvider piProvider,
      String mode,
      ) async {
    setState(() {
      _error = null;
    });
    try {
      final client = _buildClient(piProvider);
      await client.setMode(mode);
      await _refreshState(piProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mode set to $mode')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set mode: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final piProvider = Provider.of<PiConnectionProvider>(context);
    final status = piProvider.connectionStatus;
    final connected = status.isConnected;

    return Card(
      margin: const EdgeInsets.all(12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                const Text(
                  'Personality / Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh state from Pi',
                  onPressed: connected && !_loadingState
                      ? () => _refreshState(piProvider)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!connected)
              const Text(
                'Not connected to Pi. Check network first.',
                style: TextStyle(color: Colors.redAccent),
              ),
            if (connected) ...[
              if (_loadingState)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                ),
              if (_piState != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Mode: ${_piState!.mode} | Emotion: ${_piState!.emotion}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ElevatedButton(
                    onPressed: () => _setEmotion(piProvider, 'neutral'),
                    child: const Text('Neutral'),
                  ),
                  ElevatedButton(
                    onPressed: () => _setEmotion(piProvider, 'happy'),
                    child: const Text('Happy'),
                  ),
                  ElevatedButton(
                    onPressed: () => _setEmotion(piProvider, 'focused'),
                    child: const Text('Focused'),
                  ),
                  ElevatedButton(
                    onPressed: () => _setEmotion(piProvider, 'annoyed'),
                    child: const Text('Annoyed'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton(
                    onPressed: () => _setMode(piProvider, 'idle'),
                    child: const Text('Idle'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setMode(piProvider, 'listen'),
                    child: const Text('Listen'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setMode(piProvider, 'explore'),
                    child: const Text('Explore'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setMode(piProvider, 'dock'),
                    child: const Text('Dock'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
