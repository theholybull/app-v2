# Viam Pi Integration - Android Phone Module

A comprehensive Flutter application that transforms Google Pixel 4a into a modular Viam component for Raspberry Pi robots, replacing OAK IMU and adding facial recognition, communication, and emotional display capabilities.

## 🎯 Key Features

### 🔌 **Direct Pi Integration**
- ✅ USB connection to Raspberry Pi (10.10.10.x subnet)
- ✅ Auto-connect on boot and USB attachment
- ✅ Direct gRPC connection to viam-agent (port 8080)
- ✅ No cloud dependency - local-only operation
- ✅ Background service for persistent connection

### 🤖 **Advanced Robotics Components**

**IMU Replacement**
- ✅ High-precision phone sensors replace OAK BMI270
- ✅ Accelerometer, Gyroscope, Magnetometer fusion
- ✅ 100Hz sensor data streaming
- ✅ Real-time motion detection and orientation

**Smart Camera System**
- ✅ Dual camera operation alongside OAK-D
- ✅ Face detection and recognition with ML Kit
- ✅ Person tracking during conversations
- ✅ Emotion detection from facial expressions
- ✅ Front camera for interaction, rear for environment

**Communication System**
- ✅ Professional microphone array for speech recognition
- ✅ High-quality speaker output for robot voice
- ✅ Real-time audio processing and streaming
- ✅ Noise reduction and echo cancellation

**Emotional Display**
- ✅ Dynamic eye animations showing robot emotions
- ✅ Steering wheel direction visualization
- ✅ Person tracking eye movement
- ✅ 10+ emotion states (happy, sad, angry, curious, etc.)
- ✅ Real-time eye tracking and blinking

## 🤖 Robot Integration

### Raspberry Pi Compatibility
- **Direct USB Connection**: 10.10.10.67 ↔ 10.10.10.1
- **Viam Agent Integration**: Connects to port 8080
- **Component Registration**: Auto-registers as Viam module
- **Real-time Data**: Low-latency sensor and camera streaming

### Component Replacements
- **OAK IMU → Phone Sensors**: Higher accuracy, better calibration
- **Add Face Recognition**: ML Kit powered face detection
- **Voice Interface**: Professional audio I/O
- **Emotional Display**: Interactive robot personality

### Hardware Specifications
- **Display**: 5.81" OLED for emotional eyes and status
- **Processor**: Snapdragon 730G for real-time ML processing
- **Sensors**: Industrial-grade IMU with sensor fusion
- **Audio**: 3-mic array + stereo speakers
- **Cameras**: Dual cameras for interaction and navigation
- **Connectivity**: USB-C tethering for reliable connection

## 🔧 Installation & Setup

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Android SDK 23 or higher
- Google Pixel 4a device
- Raspberry Pi with Viam agent installed
- USB-C cable (data-capable)

### Hardware Setup
1. **Connect Phone to Pi**: Use USB-C cable to connect Pixel 4a to Raspberry Pi
2. **Enable USB Tethering**: Settings → Network → USB tethering
3. **Configure Network**: Phone gets 10.10.10.1, Pi gets 10.10.10.67
4. **Test Connection**: `ping 10.10.10.1` from Pi

### Software Setup

1. **Clone and build the app**
   ```bash
   git clone <repository-url>
   cd viam_pi_integration
   flutter pub get
   flutter build apk --release
   ```

2. **Install on Pixel 4a**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Configure Raspberry Pi**
   - Update `/etc/viam.json` (see `pi_integration_config.md`)
   - Remove problematic `oak-bmi270-imu` module
   - Add phone integration components
   - Restart viam-agent: `sudo systemctl restart viam-agent`

4. **Enable Auto-Start**
   - Grant all permissions when prompted
   - Enable "Ignore battery optimizations"
   - Allow "Display over other apps"
   - USB connection will trigger auto-connection

### Viam Configuration Update

Replace your current OAK IMU and add phone components:

```json
{
  "components": [
    {
      "name": "phone_imu",
      "api": "rdk:component:movement_sensor", 
      "model": "rdk:builtin:fake",
      "attributes": {"integration_type": "phone_sensors"}
    },
    {
      "name": "phone_front_camera",
      "api": "rdk:component:camera",
      "model": "rdk:builtin:webcam", 
      "attributes": {"integration_type": "phone_camera"}
    },
    {
      "name": "phone_display",
      "api": "rdk:component:board",
      "model": "rdk:builtin:fake",
      "attributes": {"integration_type": "phone_display"}
    }
  ]
}
```

## 🚀 Usage Guide

### Quick Start

1. **Physical Setup**: Connect phone to Pi via USB-C cable
2. **Enable USB Tethering**: On phone, enable USB network sharing
3. **Launch App**: App auto-starts or launch manually
4. **Check Connection**: Verify Pi connection status (green USB icon)
5. **Test Components**: Use "Test All" to verify integration

### USB Connection Management

- **Auto-Connect**: App automatically discovers Pi on USB
- **Manual Connect**: Enter Pi IP (10.10.10.67) if needed
- **Status Monitoring**: Real-time ping and connection health
- **Boot-on-Start**: App launches automatically on phone boot

### Robot Features

**IMU Sensors** (Replaces OAK BMI270)
- Real-time accelerometer, gyroscope, magnetometer data
- 100Hz update rate for precise motion control
- Sensor fusion for accurate orientation
- Direct integration with navigation and SLAM

**Face Detection & Tracking**
- ML Kit powered face recognition
- Person tracking during conversations
- Emotion detection from facial expressions
- Automatic eye tracking on display

**Emotional Display System**
- Dynamic eye animations with 10+ emotions
- Steering wheel direction visualization
- Real-time blinking and pupil movement
- Personality-driven emotion changes

**Voice Communication**
- Professional microphone input for speech recognition
- High-quality speaker output for robot voice
- Noise reduction and echo cancellation
- Real-time audio streaming to/from Pi

### Component Status

The app registers these components with Viam:
- `phone_imu` - High-precision movement sensors
- `phone_front_camera` - Face detection camera
- `phone_rear_camera` - Environment monitoring
- `phone_microphone` - Speech input
- `phone_speaker` - Voice output
- `phone_display` - Emotional eyes and status

## 📋 API Reference

### Viam Commands

**IMU Sensor Commands**
- `get_sensor_readings` - Returns fused IMU data (accel, gyro, mag)
- `get_angular_velocity` - High-precision gyroscope data
- `get_orientation` - Device orientation and heading
- `get_linear_acceleration` - Gravity-corrected acceleration

**Camera & Vision Commands**
- `capture_image` - High-resolution photo capture
- `start_face_detection` - Enable face recognition
- `get_detected_faces` - Returns face bounding boxes and emotions
- `track_person` - Start tracking specific person
- `stop_tracking` - Stop person tracking

**Display & Emotion Commands**
- `set_emotion` - Set robot emotional state (happy, sad, angry, etc.)
- `set_eye_position` - Control eye direction
- `set_steering_angle` - Visualize steering direction
- `start_person_tracking` - Track person with eye movement
- `blink` - Trigger eye blink animation

**Audio Commands**
- `start_speech_recognition` - Begin voice input
- `stop_speech_recognition` - Stop and return transcript
- `speak_text` - Convert text to speech
- `play_audio_file` - Play custom audio
- `set_volume` - Control speaker volume

### Real-time Data Streams

**Sensor Streams**
- `imu_stream` - 100Hz fused sensor data
- `orientation_stream` - Real-time orientation quaternions
- `motion_detection` - Movement events and classification

**Vision Streams**
- `face_detection_stream` - Face locations and emotions
- `person_tracking_stream` - Tracked person positions
- `camera_frames_stream` - Real-time video frames

**Audio Streams**
- `microphone_stream` - Raw audio input
- `speech_recognition_stream` - Real-time transcription
- `emotion_detection_stream` - Voice emotion analysis

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── providers/                # State management
│   ├── sensor_provider.dart  # Sensor data handling
│   ├── audio_provider.dart   # Audio recording/playback
│   ├── camera_provider.dart  # Camera operations
│   └── viam_provider.dart    # Viam connection
├── screens/                  # UI screens
│   └── home_screen.dart      # Main dashboard
├── widgets/                  # Reusable UI components
│   ├── sensor_card.dart      # Sensor display widget
│   ├── audio_controls.dart   # Audio control widget
│   ├── camera_preview.dart   # Camera preview widget
│   ├── viam_connection.dart  # Viam settings dialog
│   └── device_info_card.dart # Device information display
└── services/                 # Utility services
    └── permission_service.dart # Permission handling
```

### Key Dependencies

- `viam_sdk`: Viam platform integration
- `sensors_plus`: Android sensor access
- `camera`: Camera functionality
- `record`: Audio recording
- `just_audio`: Audio playback
- `provider`: State management
- `permission_handler`: Runtime permissions

## Troubleshooting

### Common Issues

**Permission Denied Errors**
- Ensure all permissions are granted in Android settings
- Check that the app has background location access if needed

**Connection Issues**
- Verify Viam credentials are correct
- Check network connectivity
- Ensure robot address is reachable
- Try enabling/disabling "Auto Reconnect"

**Camera Not Working**
- Check if another app is using the camera
- Restart the app to reset camera controllers
- Verify camera permissions in Android settings

**Audio Recording Issues**
- Check microphone permissions
- Ensure no other app is recording
- Test with different audio formats if needed

### Debug Mode

Enable debug logging by modifying the logger configuration in provider classes:

```dart
Logger.level = Level.debug;
```

### Logs and Diagnostics

- View app logs using `adb logcat`
- Check Viam dashboard for connection status
- Use the "View Logs" button in the app for internal logs

## Development

### Building from Source

1. **Set up Flutter environment**
   ```bash
   flutter doctor
   flutter precache
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run in development mode**
   ```bash
   flutter run
   ```

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Support

- **Documentation**: [Viam Documentation](https://docs.viam.com/)
- **Flutter SDK**: [Viam Flutter SDK](https://flutter.viam.dev/)
- **Issues**: Report issues via GitHub Issues
- **Community**: [Viam Community](https://community.viam.com/)

## Changelog

### v1.0.0
- Initial release
- Full sensor integration for Pixel 4a
- Viam platform connectivity
- Audio recording and playback
- Camera capture and streaming
- Real-time data streaming