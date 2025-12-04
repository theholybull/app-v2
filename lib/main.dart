import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/sensor_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/viam_provider.dart';
import 'providers/emotion_display_provider.dart';
import 'providers/face_detection_provider.dart';
import 'providers/pi_connection_provider.dart';

import 'core/background_service.dart';
import 'core/vision/vision_service.dart';
import 'providers/personality_provider.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundService.initialize();

  runApp(const ViamPixel4aApp());
}

class ViamPixel4aApp extends StatelessWidget {
  const ViamPixel4aApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SensorProvider()..startMonitoring(),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CameraProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ViamProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PiConnectionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => EmotionDisplayProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FaceDetectionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VisionService(),
        ),
        ChangeNotifierProvider(
          create: (_) => PersonalityProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Viam Pi Integration',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
