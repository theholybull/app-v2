# Viam Pixel 4a Integration Guide
## Complete Wiring, Ports, Protocols & Setup Instructions

---

## 📋 Overview
This guide shows how to integrate your Google Pixel 4a as a Viam robot module, providing:
- High-precision IMU sensor data (replacing problematic OAK-D BMI270)
- Face detection and person tracking
- Audio communication (microphone/speaker)
- Emotional display system with animated eyes
- Direct USB/WiFi connection to Raspberry Pi

---

## 🔌 Physical Connection Setup

### Option 1: USB Connection (Recommended)
**Hardware Needed:**
- USB-C cable (Pixel 4a to Pi USB-A port)
- Raspberry Pi 4/5 with USB OTG support

**Wiring:**
```
Pixel 4a USB-C port → USB-C cable → Raspberry Pi USB 3.0 port (blue)
```

**Network Configuration:**
- **Pi**: `10.10.10.67` (USB tethering gateway)
- **Phone**: `10.10.10.1` (USB tethering client)
- **Advantage**: Direct, stable connection, no WiFi interference

### Option 2: WiFi Connection
**Hardware Needed:**
- Both devices on same WiFi network

**Network Configuration:**
- **Pi**: `192.168.42.116` (your current setup)
- **Phone**: `192.168.42.129` (your current setup)
- **Advantage**: Wireless, more flexible positioning

---

## 🌐 Network Ports & Protocols

### Viam Communication
| Port | Protocol | Purpose | Source → Destination |
|------|----------|---------|----------------------|
| **8080** | gRPC | Viam agent API | Phone → Pi |
| **8080** | HTTP | Viam web interface | Browser → Pi |
| **22** | SSH | Remote access/debug | Phone/Computer → Pi |

### App Communication Channels
| Port | Protocol | Purpose | Used For |
|------|----------|---------|----------|
| **22** | TCP | Watchdog testing | Pi connectivity verification |
| **8080** | gRPC | Sensor data streaming | IMU, face detection, audio |
| **Dynamic** | WebSocket | Real-time communication | Bidirectional data exchange |

### Data Flow
```
Phone Sensors → gRPC (8080) → Viam Agent → Robot Control
Viam Commands → gRPC (8080) → Phone App → Actuator Response
```

---

## 🍓 Raspberry Pi Setup

### 1. Install Viam Agent
```bash
# Install Viam agent
curl https://storage.googleapis.com/packages.viam.com/apps/viam-agent-arm64.sh | bash

# Enable and start service
sudo systemctl enable viam-agent
sudo systemctl start viam-agent
```

### 2. Configure Network
```bash
# For USB tethering (if using Option 1)
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i usb0 -o wlan0 -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o usb0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save rules
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```

### 3. Configure Viam Server
```json
{
  "network": {
    "bind_address": "0.0.0.0:8080"
  },
  "components": [
    {
      "name": "imu_sensor",
      "type": "movement_sensor",
      "model": "viam-singlesingle",
      "attributes": {
        "integration_model_id": "phone_imu"
      }
    },
    {
      "name": "camera_front",
      "type": "camera",
      "model": "viam-webcam",
      "attributes": {
        "integration_model_id": "phone_camera"
      }
    },
    {
      "name": "audio_input",
      "type": "input",
      "model": "viam-audio",
      "attributes": {
        "integration_model_id": "phone_microphone"
      }
    },
    {
      "name": "audio_output",
      "type": "output",
      "model": "viam-audio",
      "attributes": {
        "integration_model_id": "phone_speaker"
      }
    }
  ]
}
```

### 4. Verify Viam Installation
```bash
# Check if Viam is running
curl http://localhost:8080

# Check logs
sudo journalctl -u viam-agent -f
```

---

## 📱 Android App Configuration

### App Permissions Required
- **Camera**: Face detection and streaming
- **Microphone**: Voice commands and audio input
- **Storage**: Configuration and data caching
- **Location**: GPS data (optional)
- **Network**: WiFi/USB communication
- **Background**: Persistent connection service

### App Settings & Configuration
```
Connection Settings:
├── Pi IP Address: 192.168.42.116 (auto-discovered)
├── Port: 8080 (Viam agent)
├── Connection Type: WiFi/USB (auto-detect)
└── Auto-connect: Enabled

Sensor Settings:
├── IMU Rate: 100Hz
├── Camera Resolution: 640x480
├── Face Detection: Enabled
└── Audio Sample Rate: 16kHz
```

---

## 🚦 Integration Workflow

### 1. Initial Setup
```bash
# On Pi - ensure Viam is ready
sudo systemctl status viam-agent
curl http://localhost:8080/api/v1/health

# On Phone - install and configure app
adb install app-release.apk
# Grant all permissions when prompted
```

### 2. Connection Sequence
1. **Phone starts app** → Auto-discovers Pi IP
2. **Ping test** → Verifies connectivity (port 22)
3. **gRPC handshake** → Connects to Viam agent (port 8080)
4. **Authentication** → Exchange API keys if configured
5. **Service registration** → Registers sensors as Viam components
6. **Data streaming** → Starts sending sensor data

### 3. Data Exchange Protocols

#### IMU Sensor Data
```protobuf
// gRPC message structure
message SensorReading {
  double linear_acceleration_x
  double linear_acceleration_y
  double linear_acceleration_z
  double angular_velocity_x
  double angular_velocity_y
  double angular_velocity_z
  int64 timestamp_ms
}
```

#### Face Detection Events
```json
{
  "faces": [
    {
      "id": "face_001",
      "bounding_box": {"x": 100, "y": 150, "width": 80, "height": 100},
      "confidence": 0.95,
      "landmarks": {...}
    }
  ],
  "timestamp": "2025-11-06T09:14:45Z"
}
```

#### Audio Data
```protobuf
message AudioChunk {
  bytes audio_data
  int32 sample_rate
  int32 channels
  int64 timestamp
}
```

---

## 🛠️ Troubleshooting & Diagnostics

### Connection Issues
```bash
# Test Pi connectivity from phone (in app terminal)
ping 192.168.42.116
telnet 192.168.42.116 8080

# On Pi - check what's listening
sudo netstat -tlnp | grep 8080
sudo ss -tlnp | grep 8080
```

### Common Issues & Solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| "Connection refused" | Viam agent not running | `sudo systemctl restart viam-agent` |
| "Authentication failed" | API key mismatch | Update Viam config or use no-auth mode |
| "No sensor data" | Permissions denied | Grant camera/microphone permissions |
| "High latency" | WiFi interference | Use USB connection instead |

### Debug Commands
```bash
# Pi logs
sudo journalctl -u viam-agent -f

# Network status
ip route show
arp -n

# Process status
ps aux | grep viam
sudo systemctl status viam-agent
```

---

## 📊 Performance Optimization

### Network Optimization
```bash
# On Pi - prioritize Viam traffic
sudo tc qdisc add dev wlan0 root handle 1: htb default 12
sudo tc class add dev wlan0 parent 1: classid 1:1 htb rate 1000mbit
sudo tc class add dev wlan0 parent 1:1 classid 1:12 htb rate 900mbit ceil 1000mbit prio 0
```

### Android Battery Optimization
```xml
<!-- AndroidManifest.xml optimizations -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Data Rate Configuration
```dart
// In app - adjust based on your needs
final sensorConfig = {
  'imu_rate': 100,        // Hz (10-200)
  'camera_fps': 30,       // Frames per second
  'audio_buffer_size': 1024, // Samples
  'compression': 'jpeg',  // Image compression
};
```

---

## 🔒 Security Configuration

### Network Security
```bash
# On Pi - firewall rules
sudo ufw allow 8080/tcp  # Viam agent
sudo ufw allow 22/tcp    # SSH
sudo ufw enable

# Optional: VPN for remote access
sudo apt install wireguard
# Configure WireGuard for secure remote access
```

### API Authentication
```json
{
  "auth": {
    "type": "api-key",
    "api_key": {
      "id": "your-api-key-id",
      "key": "your-secret-api-key"
    }
  }
}
```

---

## 📈 Monitoring & Logging

### App Logs
```bash
# Android debug logs
adb logcat -s ViamPiApp
adb logcat -s FlutterViam

# Export logs
adb logcat -d > phone_logs.txt
```

### Pi Monitoring
```bash
# Resource usage
htop
iotop -o
nethogs wlan0

# Viam-specific metrics
curl http://localhost:8080/api/v1/health
curl http://localhost:8080/api/v1/components
```

---

## 🚀 Advanced Features

### Custom Sensor Fusion
```dart
// Combine IMU with other sensors for better accuracy
class SensorFusion {
  void fuseIMUWithGPS(IMUData imu, GPSData gps) {
    // Kalman filter implementation
    var filtered = kalmanFilter.update(imu, gps);
    sendToViam(filtered);
  }
}
```

### Edge Processing
```dart
// Process faces on phone before sending
class FaceProcessor {
  List<Face> detectFaces(CameraImage image) {
    final faces = mlKitFaceDetector.processImage(image);
    return faces.where((f) => f.confidence > 0.8).toList();
  }
}
```

---

## 📞 Support & Resources

### Quick Reference
- **Pi IP**: 192.168.42.116
- **Phone IP**: 192.168.42.129
- **Viam Port**: 8080
- **SSH Port**: 22
- **Protocol**: gRPC + WebSocket

### Documentation Links
- [Viam Documentation](https://docs.viam.com/)
- [Flutter gRPC Guide](https://grpc.io/docs/languages/flutter/quickstart/)
- [Android Background Services](https://developer.android.com/guide/components/services)

### Emergency Commands
```bash
# Restart everything
sudo systemctl restart viam-agent
adb reboot

# Reset network
sudo dhclient wlan0
adb shell svc wifi disable && adb shell svc wifi enable
```

---

## ✅ Success Checklist

- [ ] Raspberry Pi Viam agent installed and running
- [ ] Network connectivity established (WiFi or USB)
- [ ] Android app installed with all permissions
- [ ] App auto-discovers Pi and connects successfully
- [ ] IMU sensor data streaming to Viam
- [ ] Face detection working
- [ ] Audio communication functional
- [ ] Emotional display system active
- [ ] All sensors registered in Viam interface
- [ ] Performance optimized (low latency, stable connection)

---

**🎉 Your Viam Pixel 4a integration is now complete!** 

You now have a high-precision Android sensor module that replaces the problematic OAK-D IMU and adds advanced features like face recognition and communication capabilities.