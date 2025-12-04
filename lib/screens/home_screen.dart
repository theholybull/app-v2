import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:viam_pixel4a_sensors/widgets/pi_connection_widget.dart';
import 'package:viam_pixel4a_sensors/widgets/viam_connection.dart';
import 'package:viam_pixel4a_sensors/widgets/sensor_card.dart';
import 'package:viam_pixel4a_sensors/widgets/camera_preview.dart';
import 'package:viam_pixel4a_sensors/widgets/audio_controls.dart';
import 'package:viam_pixel4a_sensors/widgets/emotion_display.dart';
import 'package:viam_pixel4a_sensors/widgets/face_detection_controls.dart';
import 'package:viam_pixel4a_sensors/widgets/personality_panel.dart';
import 'package:viam_pixel4a_sensors/widgets/device_info_card.dart';

import 'package:viam_pixel4a_sensors/providers/pi_connection_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final piProvider = context.watch<PiConnectionProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kilo Head Control'),
          centerTitle: false,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.face_retouching_natural), text: 'Avatar & Rig'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'AI'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: DASHBOARD ---
            _buildDashboardTab(context, piProvider),

            // --- TAB 2: AVATAR & RIG (eyes/head/human avatar/pogo stick) ---
            _buildAvatarTab(context),

            // --- TAB 3: AI (placeholder for now, API wiring next) ---
            _buildAiTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
      BuildContext context,
      PiConnectionProvider piProvider,
      ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Simple hook point if you want to re-ping the Pi or Viam later.
        await piProvider.refreshStatus();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            // Pi connection + health
            PiConnectionWidget(),
            SizedBox(height: 12),

            // Viam connection card
            ViamConnectionWidget(),
            SizedBox(height: 12),

            // Device info / sensors
            DeviceInfoCard(),
            SizedBox(height: 12),

            SensorCard(),
            SizedBox(height: 12),

            // Camera feed
            CameraPreviewCard(),
            SizedBox(height: 12),

            // Audio controls
            AudioControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EmotionDisplay(),
          const SizedBox(height: 12),
          const FaceDetectionControls(),
          const SizedBox(height: 12),
          const PersonalityPanel(),
          const SizedBox(height: 12),

          // Placeholder for sprite / avatar sheet config.
          // This keeps the concept in from day one; we’ll wire storage + file
          // selection + Pi sync on the next pass.
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Avatar Sprites & Rig',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This is where you’ll hook up sprite sheets and avatar '
                        'definitions for human avatars, robot heads, pogo sticks, '
                        'or whatever else you strap this brain onto.\n\n'
                        'Next step: we’ll add fields to point at sprite PNGs / '
                        'atlas JSON and sync that config back to the Pi.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTab(BuildContext context) {
    // For now this is just a clean shell; next step,
    // we drop in the AI provider + chat UI + API calls.
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 48),
            SizedBox(height: 16),
            Text(
              'AI brain hookup is next.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'This tab will host the persona-aware chat, adult-mode toggle, '
                  'and whatever API we bolt on (Pi local or cloud).',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
