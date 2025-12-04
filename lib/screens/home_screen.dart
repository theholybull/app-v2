// lib/screens/home_screen.dart
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

            // --- TAB 2: AVATAR & RIG ---
            _buildAvatarTab(context),

            // --- TAB 3: AI ---
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
    // For now, no explicit pull-to-refresh; Pi widget handles its own refresh.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pi connection + health
          const PiConnectionWidget(),
          const SizedBox(height: 12),

          // Viam connection card
          ViamConnectionWidget(),
          const SizedBox(height: 12),

          // Device info / sensors
          const DeviceInfoCard(),
          const SizedBox(height: 12),

          const SensorCard(),
          const SizedBox(height: 12),

          // Camera feed
          CameraPreviewCard(),
          const SizedBox(height: 12),

          // Audio controls
          AudioControls(),
        ],
      ),
    );
  }

  Widget _buildAvatarTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmotionDisplay(),
          const SizedBox(height: 12),
          FaceDetectionControls(),
          const SizedBox(height: 12),
          PersonalityPanel(),
          const SizedBox(height: 12),

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
                    'Configure sprite sheets and avatar rigs here – whether it’s '
                        'a human face, robot head, or a pogo stick with feelings. '
                        'Next pass we’ll add fields for sprite PNGs / atlas JSON and '
                        'sync that config to the Pi.',
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
              'This tab will host persona-aware chat, adult-mode toggles, and '
                  'whichever AI backend you point it at.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
