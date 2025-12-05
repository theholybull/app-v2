// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/background_service.dart';
import 'screens/home_screen.dart';

// Providers
import 'providers/sensor_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/viam_provider.dart';
import 'providers/pi_connection_provider.dart';
import 'providers/emotion_display_provider.dart';
import 'providers/face_detection_provider.dart';
import 'providers/personality_provider.dart';

// Vision core
import 'core/vision/vision_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // VisionService is a plain service, not a ChangeNotifier.
        Provider<VisionService>(
          create: (_) => VisionService(),
        ),

        ChangeNotifierProvider<SensorProvider>(
          create: (_) => SensorProvider(),
        ),
        ChangeNotifierProvider<AudioProvider>(
          create: (_) => AudioProvider(),
        ),
        ChangeNotifierProvider<CameraProvider>(
          create: (_) => CameraProvider(),
        ),
        ChangeNotifierProvider<ViamProvider>(
          create: (_) => ViamProvider(),
        ),
        ChangeNotifierProvider<PiConnectionProvider>(
          create: (_) => PiConnectionProvider(),
        ),
        ChangeNotifierProvider<EmotionDisplayProvider>(
          create: (_) => EmotionDisplayProvider(),
        ),
    ChangeNotifierProvider(
    create: (_) => PersonalityProvider(
    piBaseUrl: 'http://kilo.local:8090',   // fallback default
    ),
    ),

    ),
        ChangeNotifierProvider<PersonalityProvider>(
          create: (_) => PersonalityProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Kilo Head',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
