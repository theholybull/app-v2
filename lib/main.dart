import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/sensor_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/viam_provider.dart';
import 'providers/pi_connection_provider.dart';
import 'providers/emotion_display_provider.dart';
import 'providers/face_detection_provider.dart';
import 'screens/home_screen.dart';
import 'services/permission_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Initialize permission service
  await PermissionService.initialize();
  
  // Initialize background service handlers
  BackgroundService.initializeServiceHandlers(
    onUsbAttached: (data) {
      print('USB device attached: ${data['device_name']}');
      // Will be handled by providers
    },
    onUsbDetached: (data) {
      print('USB device detached: ${data['device_name']}');
      // Will be handled by providers
    },
    onAutoStart: (data) {
      print('Auto-start triggered at: ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'])}');
      // Will be handled by providers
    },
  );
  
  runApp(const ViamPixel4aApp());
}

class ViamPixel4aApp extends StatelessWidget {
  const ViamPixel4aApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()..startMonitoring()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => ViamProvider()),
        ChangeNotifierProvider(create: (_) => PiConnectionProvider()),
        ChangeNotifierProvider(create: (_) => EmotionDisplayProvider()),
        ChangeNotifierProvider(create: (_) => FaceDetectionProvider()),
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