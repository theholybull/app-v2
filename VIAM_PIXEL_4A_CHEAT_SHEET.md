# Viam Pixel 4a Integration Cheat Sheet

## Overview
The Pixel 4a app serves as a comprehensive robotics module providing sensors, face detection, emotional display, and communication capabilities to your Viam-powered robot.

## Architecture Overview

```
Pixel 4a Phone ←→ USB Tethering ←→ Raspberry Pi ←→ Viam Agent ←→ Your Robot
     ↓                        ↓                ↓              ↓
   App UI               Network Config      gRPC API      Robot Control
   (Flutter)              (10.10.10.x)       (Port 8080)    (Components)
```

## Core Components & Data Flow

### 1. Sensor Provider
- **Function**: Replaces OAK-D IMU with high-precision phone sensors
- **Data**: Accelerometer, gyroscope, magnetometer at 100Hz
- **Output**: IMU data stream for robot balance/orientation

### 2. Face Detection Provider  
- **Function**: ML Kit real-time face detection and tracking
- **Data**: Face bounding boxes, emotions, head pose angles
- **Output**: Person location tracking for robot attention

### 3. Emotion Display Provider
- **Function**: Renders animated eyes showing robot emotions
- **Data**: Eye position, emotion state, pupil tracking
- **Output**: Visual feedback for robot personality

### 4. Audio Provider
- **Function**: Professional bidirectional audio communication
- **Data**: Microphone input, speaker output, voice processing
- **Output**: Voice interface for robot interaction

### 5. Pi Connection Provider
- **Function**: USB tethering connection management
- **Data**: Network status, ping monitoring, auto-reconnect
- **Output**: Stable communication channel

### 6. Viam Provider
- **Function**: Direct gRPC communication with Viam agent
- **Data**: Sensor streams, commands, status updates
- **Output**: Integration with Viam robotics platform

## Network Configuration

### Default USB Tethering Setup
```
Phone IP:    10.10.10.1
Pi IP:       10.10.10.67
Subnet:      255.255.255.0
Gateway:     10.10.10.1
```

### Port Mapping
```
Port 8080:   Viam gRPC API (primary communication)
Port 22:     SSH/Ping testing
Port 5000+:  Additional services (if needed)
```

### Connection Endpoints
```
Viam Agent:  10.10.10.67:8080
SSH:         10.10.10.67:22
Web UI:      (Phone app itself)
```

## Personality Integration Hooks

### 1. Emotion States (Enum)
```dart
enum Emotion {
  happy,      // 😊 Friendly, engaged
  sad,        // 😢 Disappointed, low energy
  angry,      // 😠 Frustrated, alert
  surprised,  // 😮 Alert, discovery
  neutral,    // 😐 Default, listening
  curious,    // 🤒 Inquisitive, learning
  focused,    // 🎯 Concentrating, task mode
  sleepy,     // 😴 Low power, resting
  excited,    // 🤉 High energy, celebration
  confused,   // 😕 Uncertain, processing
}
```

### 2. Eye Movement Controls
```dart
// Direct eye positioning
emotionProvider.setEyePosition(leftX: 0.5, leftY: 0.5, rightX: 0.5, rightY: 0.5)

// Look at person (face tracking)
emotionProvider.lookAtPerson(faceBoundingBox)

// Steering direction (for robot movement)
emotionProvider.setSteeringDirection(angle: -30, speed: 0.8)

// Emotion transitions
emotionProvider.setEmotion(Emotion.happy, duration: Duration(seconds: 1))
```

### 3. Sensor Data Integration
```dart
// IMU data for robot balance
sensorProvider.accelerometerStream.listen((data) {
  // Send to robot for balance/orientation
  robot.updateOrientation(data.values);
});

// Face detection for attention
faceProvider.detectedFacesStream.listen((faces) {
  if (faces.isNotEmpty) {
    // Track primary person
    robot.focusOnPerson(faces.first);
  }
});
```

## Viam Component Configuration

### Sensor Module (Replacement for OAK-D)
```json
{
  "name": "phone_imu",
  "type": "movement_sensor",
  "model": "phone_imu",
  "attributes": {
    "data_frequency_hz": 100
  }
}
```

### Camera Module (Face Detection)
```json
{
  "name": "phone_camera",
  "type": "camera", 
  "model": "phone_face_detection",
  "attributes": {
    "face_detection_enabled": true,
    "emotion_detection": true,
    "fps": 30
  }
}
```

### Audio Module (Voice Interface)
```json
{
  "name": "phone_audio",
  "type": "audio_input",
  "model": "phone_microphone",
  "attributes": {
    "sample_rate": 16000,
    "channels": 1,
    "noise_reduction": true
  }
}
```

### Display Module (Emotional Eyes)
```json
{
  "name": "phone_display", 
  "type": "display",
  "model": "phone_emotion_display",
  "attributes": {
    "resolution": "1080x2340",
    "refresh_rate": 60,
    "emotion_states": 10
  }
}
```

## Personality Integration Patterns

### 1. Emotion Triggers
```python
# Example: When robot detects obstacle
async def on_obstacle_detected():
    phone_display.set_emotion("surprised")
    phone_display.eyes_wide(duration=2)
    await asyncio.sleep(1)
    phone_display.set_emotion("focused")

# Example: When person speaks
async def on_voice_detected(person_id):
    phone_display.look_at_person(person_id)
    phone_display.set_emotion("curious")
    phone_display.start_listening_animation()
```

### 2. Sensor Response Patterns
```python
# IMU-based reactions
async def on_imu_change(acceleration, orientation):
    if acceleration.z > 9.0:  # Robot tilting
        phone_display.set_emotion("surprised")
    elif orientation.pitch > 30:  # Looking down
        phone_display.eyes_look_down()
    
# Face-based attention
async def on_face_detected(face_data):
    if face_data.smiling_probability > 0.7:
        phone_display.set_emotion("happy")
    if face_data.head_angle > 45:  # Person looking away
        phone_display.set_emotion("confused")
```

### 3. Communication Flows
```python
# Voice interaction cycle
async def voice_interaction_loop():
    while True:
        # Show listening state
        phone_display.set_emotion("curious")
        phone_audio.start_recording()
        
        # Wait for voice input
        audio_data = await phone_audio.get_voice_input()
        
        # Process and respond
        response = await personality.process_voice(audio_data)
        phone_display.set_emotion("focused")
        phone_audio.speak(response.text)
        
        # Show appropriate emotion
        phone_display.set_emotion(response.emotion)
```

## API Endpoints & Hooks

### 1. Direct gRPC Methods
```python
# Set robot emotion
await robot.phone_display.set_emotion(
    emotion="happy",
    duration_ms=2000,
    transition_type="smooth"
)

# Get sensor data
imu_data = await robot.phone_imu.get_readings()
face_data = await robot.phone_camera.get_faces()
audio_level = await robot.phone_audio.get_audio_level()

# Control eye movement
await robot.phone_display.set_eye_position(
    left_x=0.5, left_y=0.5,
    right_x=0.5, right_y=0.5,
    smooth=True
)

# Voice commands
await robot.phone_audio.speak("Hello, I'm ready!")
voice_input = await robot.phone_audio.listen(timeout=5)
```

### 2. WebSocket Events
```javascript
// Real-time sensor streams
ws.subscribe("phone/imu/data", (data) => {
  robot.update_balance(data);
});

ws.subscribe("phone/faces/detected", (faces) => {
  robot.update_attention(faces);
});

ws.subscribe("phone/audio/level", (level) => {
  robot.adjust_volume(level);
});
```

### 3. HTTP REST Hooks
```http
# Manual emotion control
POST /api/display/emotion
{
  "emotion": "happy",
  "duration": 3000,
  "intensity": 0.8
}

# Sensor configuration
PUT /api/sensors/imu/config
{
  "frequency": 100,
  "filters": ["low_pass", "calibration"]
}

# Audio playback
POST /api/audio/speak
{
  "text": "Hello world!",
  "voice": "default",
  "speed": 1.0
}
```

## Display as Eyes Configuration

### 1. Full-Screen Eye Mode
```dart
// Activate full-screen eyes
Navigator.push(context, MaterialPageRoute(
  builder: (context) => FullScreenEyesScreen()
));

// Control eye appearance
emotionProvider.setEyeStyle(
  shape: EyeShape.oval,           // Cars movie style
  irisColor: Colors.blue,
  pupilSize: 0.3,
  highlightIntensity: 0.8
);
```

### 2. Eye Animation States
```dart
// Natural blinking
emotionProvider.startBlinking(
  interval: Duration(seconds: 3),
  duration: Duration(milliseconds: 150)
);

// Personality-based eye movements
emotionProvider.setPersonalityEyes(
  personality: "friendly",
  responsiveness: 0.8,
  expressiveness: 0.9
);

// Tracking mode
emotionProvider.enablePersonTracking(
  smoothFollowing: true,
  attentionSpan: Duration(seconds: 5)
);
```

### 3. Eye Response Triggers
```python
# Voice interaction eye responses
async def on_speaking():
    phone_display.eyes_attentive()
    phone_display.slight_movement()

async def on_listening():
    phone_display.eyes_forward()
    phone_display.subtle_blinking()

async def on_thinking():
    phone_display.eyes_look_up_and_down()
    phone_display.slow_blinking()
```

## Setup & Integration Steps

### 1. Phone Configuration
1. Install app on Pixel 4a
2. Grant all permissions (camera, mic, location, etc.)
3. Enable USB tethering in Android settings
4. Connect phone to Pi via USB cable
5. Configure network (10.10.10.67 → 10.10.10.1)

### 2. Pi Configuration
1. Install Viam agent: `curl -sL https://app.viam.com/install.sh | bash`
2. Configure USB network interface
3. Update Viam robot configuration
4. Add phone components to robot setup
5. Test gRPC connection on port 8080

### 3. Robot Integration
1. Import phone modules in robot code
2. Replace OAK-D IMU with phone IMU
3. Set up emotion display callbacks
4. Configure audio I/O for personality
5. Test sensor data flow

### 4. Personality Connection
1. Map personality emotions to eye states
2. Set up voice response triggers
3. Configure sensor-based reactions
4. Test face tracking attention
5. Calibrate movement responses

## Troubleshooting Quick Guide

### Common Issues
- **USB Connection**: Check cable, enable tethering, verify IP addresses
- **Sensor Data**: Restart app, check permissions, verify Viam connection
- **Face Detection**: Ensure camera permission, good lighting, ML Kit working
- **Audio Issues**: Check microphone access, volume levels, sample rates
- **Eye Display**: Verify app in foreground, check emotion provider state

### Debug Commands
```bash
# Check USB connection
ping 10.10.10.67

# Test Viam agent
curl 10.10.10.67:8080

# Monitor sensor logs
adb logcat | grep "ViamPi"

# Check app status
adb shell dumpsys activity activities | grep "Viam"
```

This cheat sheet provides all the essential hooks, endpoints, and integration patterns needed to connect your personality system with the Pixel 4a Viam app and use it as the emotional eye display for your robot.