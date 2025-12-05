import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/camera_provider.dart';
import 'providers/viam_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/pi_connection_provider.dart';
import 'providers/emotion_display_provider.dart';
import 'providers/face_detection_provider.dart';
import 'providers/personality_provider.dart';

import 'core/vision/vision_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait – same behavior, fewer moving parts.
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  runApp(const KiloApp());
}

class KiloApp extends StatelessWidget {
  const KiloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core sensor / audio / camera / viam plumbing
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => ViamProvider()),
        ChangeNotifierProvider(create: (_) => PiConnectionProvider()),
        ChangeNotifierProvider(create: (_) => EmotionDisplayProvider()),

        // Vision service is just a plain service object, not a ChangeNotifier
        Provider<VisionService>(create: (_) => VisionService()),

        // Face detection hooks into VisionService only (matches your ctor)
        ChangeNotifierProvider(
          create: (ctx) => FaceDetectionProvider(
            visionService: ctx.read<VisionService>(),
          ),
        ),

        // Personality / AI config (Pi backend + avatar/sprite config)
        ChangeNotifierProvider(
          create: (_) => PersonalityProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Kilo Companion',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.tealAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
