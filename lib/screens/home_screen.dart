// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pi_connection_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/personality_provider.dart';
import '../providers/emotion_display_provider.dart';
import '../core/vision/vision_service.dart';
import '../widgets/personality_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _piSyncConfigured = false;
  VoidCallback? _piListener;

  @override
  void initState() {
    super.initState();

    // Defer all provider work until after the first frame so context is valid.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pi = context.read<PiConnectionProvider>();
      final sensors = context.read<SensorProvider>();
      final personality = context.read<PersonalityProvider>();
      final emotionDisplay = context.read<EmotionDisplayProvider>();

      // 1) Start sensor subsystem on the phone
      sensors.initialize();
      sensors.startMonitoring();

      // 2) Fetch AI config/profile once
      personality.fetchAiConfig();
      personality.loadProfile();

      // 3) Auto-scan for Pi on startup
      if (!pi.connectionStatus.isConnected && !pi.isScanning) {
        pi.scanForPi();
      }

      // 4) Listen for Pi connection changes and sync base URL to other providers
      _piListener = () {
        final status = pi.connectionStatus;

        if (status.isConnected && status.piAddress != null) {
          final baseUrl = 'http://${status.piAddress}:8090';

          if (!_piSyncConfigured) {
            // Wire emotion/eyes to the Pi backend
            emotionDisplay.startHeadBackendSync(baseUrl);

            // Wire sensor push to the same backend + enable sharing
            sensors.setPiBaseUrl(baseUrl);
            sensors.setShareWithPi(true);

            // Wire personality/AI Pi endpoint
            personality.setPiBaseUrl(baseUrl);

            _piSyncConfigured = true;
          }
        } else {
          // Lost connection; allow re-sync next time.
          _piSyncConfigured = false;
        }
      };

      pi.addListener(_piListener!);

      // Run the listener once with current state so if we're already connected,
      // everything syncs immediately.
      _piListener!();
    });
  }

  @override
  void dispose() {
    final pi = context.read<PiConnectionProvider>();
    if (_piListener != null) {
      pi.removeListener(_piListener!);
    }
    super.dispose();
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
                Icon(Icons.circle, color: color, size: 12),
                const SizedBox(width: 8),
                Text(
                  'Pi connection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  isConnected ? 'Online' : (isScanning ? 'Scanning…' : 'Offline'),
                  style: TextStyle(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.refresh, size: 16),
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
                  : 'No faces detected (preview placeholder)',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
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
