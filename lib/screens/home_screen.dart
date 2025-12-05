// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pi_connection_provider.dart';
import '../core/vision/vision_service.dart';
import '../providers/personality_provider.dart';
import '../widgets/personality_panel.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off a Pi scan after first frame so context is valid.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pi = context.read<PiConnectionProvider>();
      if (!pi.connectionStatus.isConnected && !pi.isScanning) {
        pi.scanForPi();
      }
    });

    // Optionally try to load AI config/profile once on startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final personality = context.read<PersonalityProvider>();
      personality.fetchAiConfig();
      personality.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vision = context.watch<VisionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kilo Head'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final pi = context.read<PiConnectionProvider>();
          // We dropped refreshStatus – just rescan for now.
          await pi.scanForPi();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            const _PiStatusCard(),
            const SizedBox(height: 8),
            _CameraPreviewCard(vision: vision),
            const SizedBox(height: 8),
            const PersonalityPanel(),
          ],
        ),
      ),
    );
  }
}

class _PiStatusCard extends StatelessWidget {
  const _PiStatusCard();

  @override
  Widget build(BuildContext context) {
    final pi = context.watch<PiConnectionProvider>();
    final status = pi.connectionStatus;

    final isConnected = status.isConnected;
    final isScanning = pi.isScanning;

    final color = isConnected
        ? Colors.green
        : isScanning
        ? Colors.orange
        : Colors.redAccent;

    final text = isConnected
        ? 'Connected to ${status.piAddress}'
        : isScanning
        ? 'Scanning for Pi head…'
        : (status.error ?? 'Not connected');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: color),
                const SizedBox(width: 8),
                const Text(
                  'Pi / Head Connection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: pi.autoConnect,
                  onChanged: (v) => pi.setAutoConnect(v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(text),
            const SizedBox(height: 8),
            Row(
              children: [
                if (status.lastPing > 0) ...[
                  const Icon(Icons.speed, size: 16),
                  const SizedBox(width: 4),
                  Text('${status.lastPing} ms'),
                  const SizedBox(width: 16),
                ],
                if (status.connectionType != null &&
                    status.connectionType!.isNotEmpty) ...[
                  const Icon(Icons.wifi, size: 16),
                  const SizedBox(width: 4),
                  Text(status.connectionType!),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: isScanning
                      ? null
                      : () {
                    pi.scanForPi();
                  },
                  icon: isScanning
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.search),
                  label: Text(isScanning ? 'Scanning…' : 'Scan'),
                ),
                const SizedBox(width: 8),
                if (isConnected)
                  TextButton(
                    onPressed: () => pi.disconnect(),
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  final VisionService vision;

  const _CameraPreviewCard({required this.vision});

  @override
  Widget build(BuildContext context) {
    final hasFaces = vision.hasFaces;
    final numFaces = vision.numFaces;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camera / Vision',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasFaces
                  ? 'Faces detected: $numFaces'
                  : 'No faces detected yet',
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Camera preview placeholder\n(wire to live stream later)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
