# Viam Pixel 4a App User Guide
## Step-by-Step Instructions for Daily Use

---

## 📱 Getting Started

### Installation
1. **Install APK**: Transfer `app-release.apk` to your Pixel 4a
2. **Enable Unknown Sources**: Settings → Security → Install unknown apps → Allow
3. **Install App**: Tap the APK file and follow installation prompts
4. **Grant Permissions**: When prompted, allow all requested permissions

### First Launch
1. **Open App**: Tap the Viam Sensors icon
2. **Permission Screen**: Grant Camera, Microphone, Location, and Storage permissions
3. **Battery Optimization**: Tap "Allow" when asked to ignore battery optimization
4. **Auto-Connect**: App will automatically discover your Pi and connect

---

## 🎛️ Main Interface Overview

```
┌─────────────────────────────────────┐
│ 📶 Viam Pi Connection      [🟢]    │
│ IP: 192.168.42.116    Port: 8080   │
├─────────────────────────────────────┤
│ 📊 Sensor Status                   │
│ ┌─────────┬─────────┬─────────────┐ │
│ │   IMU   │ Camera  │   Audio     │ │
│ │  [🟢]   │  [🟢]   │   [🟢]     │ │
│ │ 100Hz   │  30fps  │  16kHz      │ │
│ └─────────┴─────────┴─────────────┘ │
├─────────────────────────────────────┤
│ 👤 Face Detection      [🔴 TOGGLE] │
│ 👁️ Emotional Eyes      [🔴 TOGGLE] │
│ 🎤 Audio Input         [🔴 TOGGLE] │
├─────────────────────────────────────┤
│ 🎮 Control Panel                   │
│ [🔄 Reconnect] [⚙️ Settings]     │
└─────────────────────────────────────┘
```

---

## 🔗 Connection Management

### Automatic Connection
- **Startup**: App auto-discovers Pi at `192.168.42.116`
- **Fallback**: Tries USB tethering if WiFi fails
- **Monitoring**: Continuously monitors connection health

### Manual Connection
1. Tap **⚙️ Settings** button
2. Enter **Pi IP Address**: `192.168.42.116`
3. Enter **Port**: `8080`
4. Tap **Connect**

### Connection Status Indicators
| Status | Color | Meaning |
|--------|-------|---------|
| 🟢 Connected | Green | All systems operational |
| 🟡 Connecting | Yellow | Establishing connection |
| 🔴 Disconnected | Red | Connection lost |
| 🔵 Reconnecting | Blue | Attempting to reconnect |

---

## 📡 Sensor Controls

### IMU Sensor (Movement)
- **Status**: Shows real-time accelerometer and gyroscope data
- **Sample Rate**: 100Hz (10 samples per second)
- **Data**: Linear acceleration (X,Y,Z) and angular velocity (X,Y,Z)
- **Usage**: Automatically streams to Viam as `movement_sensor`

**To Test:**
1. Move phone in different directions
2. Watch real-time values update
3. Check Viam web interface for incoming data

### Camera System
- **Resolution**: 640x480 (optimized for performance)
- **Frame Rate**: 30 FPS
- **Face Detection**: Real-time ML Kit processing
- **Streaming**: Sends frames to Viam as `camera` component

**To Test:**
1. Point camera at face or object
2. Toggle face detection on/off
3. Verify bounding boxes appear around faces

### Audio Communication
- **Input**: 16kHz, 16-bit microphone sampling
- **Output**: Speaker for robot voice responses
- **Streaming**: Real-time bidirectional audio
- **Format**: PCM audio data

**To Test:**
1. Toggle audio input on/off
2. Speak into phone - check Viam for audio data
3. Test speaker from Viam commands

---

## 🎭 Emotional Display System

### Eye Animations
The app displays animated eyes that change based on:
- **Connection status**: Happy when connected, sad when disconnected
- **Face detection**: Excited when faces detected, curious when searching
- **User interaction**: Winking when tapped, blinking naturally

### Emotion States
| Emotion | Trigger | Eye Appearance |
|---------|---------|----------------|
| 😊 Happy | Connected successfully | Wide open, curved |
| 😢 Sad | Connection lost | Droopy, half-closed |
| 🤔 Curious | No faces detected | Side-to-side movement |
| 😮 Excited | Faces detected | Wide open, bright |
| 😉 Winking | Screen tap | One eye closed briefly |
| 😴 Sleepy | Inactive | Slow blinking |

### Controlling Emotions
```dart
// You can programmatically set emotions from Viam
emotionDisplayProvider.setEmotion('happy');
emotionDisplayProvider.setEmotion('excited');
emotionDisplayProvider.setEmotion('sleepy');
```

---

## ⚙️ Settings & Configuration

### Network Settings
```
Connection Settings:
├── Pi IP Address: [192.168.42.116]
├── Port: [8080]
├── Auto-connect: [✓] Enabled
├── Connection Timeout: [5] seconds
└── Retry Interval: [2] seconds
```

### Sensor Settings
```
Performance Settings:
├── IMU Rate: [100] Hz
├── Camera FPS: [30]
├── Camera Resolution: [640x480]
├── Audio Sample Rate: [16000] Hz
├── Face Detection: [✓] Enabled
└── Eye Animations: [✓] Enabled
```

### Advanced Settings
```
Debug Options:
├── Show FPS Counter: [ ] Disabled
├── Network Logging: [ ] Disabled
├── Sensor Debug View: [ ] Disabled
└── Performance Monitor: [ ] Disabled
```

---

## 🔧 Troubleshooting

### Connection Issues
**Problem**: "Cannot connect to Pi"
**Solutions**:
1. Check Pi is running: `curl http://192.168.42.116:8080`
2. Verify network connectivity: `ping 192.168.42.116`
3. Restart Viam agent: `sudo systemctl restart viam-agent`
4. Toggle airplane mode on/off on phone

**Problem**: "Frequent disconnections"
**Solutions**:
1. Use USB connection instead of WiFi
2. Move closer to WiFi router
3. Check Pi CPU usage: `htop`
4. Reduce camera FPS in settings

### Sensor Issues
**Problem**: "No IMU data"
**Solutions**:
1. Restart app
2. Check motion permissions
3. Calibrate sensors (move phone in figure-8 pattern)

**Problem**: "Camera not working"
**Solutions**:
1. Grant camera permission
2. Check if another app is using camera
3. Restart phone
4. Clear app cache and data

**Problem**: "Audio not recording"
**Solutions**:
1. Grant microphone permission
2. Check phone is not in silent mode
3. Test with phone's voice recorder app
4. Disable noise cancellation in settings

### Performance Issues
**Problem**: "High battery drain"
**Solutions**:
1. Lower camera FPS to 15
2. Reduce IMU rate to 50Hz
3. Use USB connection (less WiFi power)
4. Enable battery optimization exception

**Problem**: "App is slow/laggy"
**Solutions**:
1. Close other apps
2. Free phone storage space
3. Restart phone
4. Check available RAM

---

## 📊 Monitoring & Diagnostics

### Real-time Status
The main screen shows:
- **Connection Quality**: Signal strength, latency, packet loss
- **Sensor Performance**: FPS, data rate, error count
- **System Resources**: Battery level, CPU usage, memory

### Debug Information
Access debug data:
1. Tap **⚙️ Settings**
2. Scroll to **Debug Options**
3. Enable **Performance Monitor**
4. Return to main screen to see metrics

### Exporting Logs
```bash
# Export app logs for debugging
adb logcat -s ViamPiApp > phone_logs.txt
adb logcat -s FlutterViam >> phone_logs.txt

# Export Pi logs
sudo journalctl -u viam-agent > pi_logs.txt
```

---

## 🎯 Best Practices

### Daily Usage
1. **Launch app first** before starting robot operations
2. **Check connection status** - should be green
3. **Verify all sensors active** before starting tasks
4. **Monitor battery level** - keep above 20%
5. **Use USB tethering** for critical operations

### Battery Optimization
- Keep phone plugged in during long operations
- Use lower camera FPS (15) for battery saving
- Disable face detection when not needed
- Use USB connection (less WiFi power consumption)

### Network Reliability
- USB connection is most stable
- Keep Pi and phone on same WiFi network
- Avoid crowded WiFi channels
- Monitor connection quality in app

---

## 🔄 Integration with Viam

### Registered Components
The app automatically registers these Viam components:

```json
{
  "components": {
    "phone_imu": {
      "type": "movement_sensor",
      "api": "ReadAngularVelocity, ReadLinearAcceleration"
    },
    "phone_camera": {
      "type": "camera", 
      "api": "GetImage, GetPointCloud"
    },
    "phone_microphone": {
      "type": "input",
      "api": "Read"
    },
    "phone_speaker": {
      "type": "output",
      "api": "Play"
    }
  }
}
```

### Accessing from Viam Code
```python
# Python example for reading phone IMU
import asyncio

async def read_phone_imu():
    imu = robot.get_component("movement_sensor", "phone_imu")
    reading = await imu.read_angular_velocity()
    print(f"Angular velocity: {reading}")

async def get_camera_image():
    camera = robot.get_component("camera", "phone_camera")
    image = await camera.get_image()
    return image
```

### Data Rates
| Sensor | Update Rate | Data Size | Latency |
|--------|-------------|-----------|---------|
| IMU | 100Hz | ~50 bytes | <10ms |
| Camera | 30fps | ~50KB/frame | <50ms |
| Audio | 16kHz | ~32KB/s | <20ms |

---

## 📞 Quick Reference Commands

### Android Debug Bridge (ADB)
```bash
# Install app
adb install app-release.apk

# Check logs
adb logcat -s ViamPiApp

# Screen recording (for demos)
adb shell screenrecord /sdcard/demo.mp4

# Pull logs
adb pull /sdcard/demo.mp4
```

### Raspberry Pi Commands
```bash
# Check Viam status
sudo systemctl status viam-agent

# Restart Viam
sudo systemctl restart viam-agent

# Check network
ping 192.168.42.129  # Ping phone
netstat -tlnp | grep 8080
```

---

## ✅ Daily Operations Checklist

### Before Starting Robot
- [ ] Phone charged (>50% battery)
- [ ] App installed and permissions granted
- [ ] Viam agent running on Pi
- [ ] Network connectivity verified
- [ ] All sensors showing green status

### During Operation
- [ ] Monitor connection quality
- [ ] Check battery level periodically
- [ ] Watch for sensor errors
- [ ] Verify data streaming to Viam

### After Operation
- [ ] Properly disconnect from Viam
- [ ] Check app logs if issues occurred
- [ ] Charge phone for next use
- [ ] Update Pi logs if needed

---

**🎉 Your Viam Pixel 4a app is now ready for production use!**

The app provides a robust, high-performance sensor module that enhances your Viam robot with Android capabilities. For additional support, refer to the technical integration guide or contact the development team.