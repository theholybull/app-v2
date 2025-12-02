import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sensor_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/viam_provider.dart';
import '../providers/pi_connection_provider.dart';
import '../providers/emotion_display_provider.dart';
import '../providers/face_detection_provider.dart';

import '../widgets/sensor_card.dart';
import '../widgets/audio_controls.dart';
import '../widgets/camera_preview.dart';
import '../widgets/viam_connection.dart';
import '../widgets/device_info_card.dart';
import '../widgets/pi_connection_widget.dart';
import '../widgets/emotion_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTestingSensors = false;
  bool _headSyncStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    // Initialize all the providers once on startup
    await Provider.of<SensorProvider>(context, listen: false).initialize();
    await Provider.of<AudioProvider>(context, listen: false).initialize();
    await Provider.of<CameraProvider>(context, listen: false).initialize();
    await Provider.of<PiConnectionProvider>(context, listen: false).initialize();
    await Provider.of<EmotionDisplayProvider>(context, listen: false).initialize();
    await Provider.of<FaceDetectionProvider>(context, listen: false).initialize();

    // Start sensor monitoring loop
    Provider.of<SensorProvider>(context, listen: false).startMonitoring();
    // NOTE: we do NOT start head-backend sync here anymore,
    // because Pi IP might not be known yet.
  }

  @override
  Widget build(BuildContext context) {
    // Watch Pi connection status here so we can start head-backend sync
    // as soon as we actually know the Pi's IP.
    final piProvider = Provider.of<PiConnectionProvider>(context);
    final emotionProvider =
    Provider.of<EmotionDisplayProvider>(context, listen: false);
    final status = piProvider.connectionStatus;

    if (!_headSyncStarted &&
        status.piAddress != null &&
        status.piAddress!.isNotEmpty) {
      _headSyncStarted = true;
      final baseUrl = 'http://${status.piAddress}:8090';

      // Defer the call to after this frame so we don't do side-effects
      // during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        emotionProvider.startHeadBackendSync(baseUrl);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viam Pi Integration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAppInfoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showLogDialog(context),
          ),
        ],
      ),
      body: Consumer4<SensorProvider, AudioProvider, CameraProvider, ViamProvider>(
        builder: (context, sensorProvider, audioProvider, cameraProvider,
            viamProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pi connection / network to the Pi box
                const PiConnectionWidget(),
                const SizedBox(height: 16),

                // Device info
                const DeviceInfoCard(),
                const SizedBox(height: 16),

                // Eyes / emotion display
                const EmotionDisplay(),
                const SizedBox(height: 16),

                // Camera preview + controls
                const CameraPreview(),
                const SizedBox(height: 16),

                // Sensor data
                const SensorCard(),
                const SizedBox(height: 16),

                // Audio controls
                const AudioControls(),
                const SizedBox(height: 16),

                // Viam connection status
                const ViamStatusWidget(),
                const SizedBox(height: 16),

                // Diagnostics
                _buildTestButtons(context, sensorProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestButtons(BuildContext context, SensorProvider sensorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diagnostics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sensors),
              label: _isTestingSensors
                  ? const Text('Testing Sensors...')
                  : const Text('Test Sensors'),
              onPressed: _isTestingSensors ? null : _testSensors,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Providers'),
              onPressed: _refreshProviders,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _testSensors() async {
    setState(() {
      _isTestingSensors = true;
    });

    try {
      await _testAllSensors();
    } finally {
      if (mounted) {
        setState(() {
          _isTestingSensors = false;
        });
      }
    }
  }

  Future<void> _refreshProviders() async {
    await _initializeProviders();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Providers refreshed')),
    );
  }

  Future<void> _testAllSensors() async {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    final accelerometerData = sensorProvider.accelerometerData;
    final gyroscopeData = sensorProvider.gyroscopeData;
    final magnetometerData = sensorProvider.magnetometerData;

    if (!mounted) return;

    String message = 'Sensor test completed - ';
    message += accelerometerData != null ? 'ACC OK ' : 'ACC NO ';
    message += gyroscopeData != null ? 'GYR OK ' : 'GYR NO ';
    message += magnetometerData != null ? 'MAG OK' : 'MAG NO';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('App Information'),
        content: Text(
          'This app integrates the Pixel with the Raspberry Pi running Viam.\n\n'
              'It shows eyes, sensor data, camera preview, and connection status.',
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Application Logs'),
        content: Text('Log viewer would be implemented here.'),
      ),
    );
  }
}
