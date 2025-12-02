# Viam Pixel 4a Quick Reference
## Essential Ports, Commands & Configuration

---

## 🌐 Network Configuration

### IP Addresses
```
Pi (Raspberry Pi):    192.168.42.116
Phone (Pixel 4a):    192.168.42.129
```

### Critical Ports
| Port | Protocol | Purpose | Direction |
|------|----------|---------|-----------|
| **8080** | gRPC | Viam agent API | Phone ↔ Pi |
| **8080** | HTTP | Viam web interface | Browser → Pi |
| **22** | SSH | Remote access | Phone/PC → Pi |
| **22** | TCP | Connectivity test | Phone → Pi |

---

## 🚀 Quick Start Commands

### Raspberry Pi Setup
```bash
# Install Viam agent
curl https://storage.googleapis.com/packages.viam.com/apps/viam-agent-arm64.sh | bash

# Start Viam service
sudo systemctl enable viam-agent
sudo systemctl start viam-agent

# Check status
sudo systemctl status viam-agent
curl http://localhost:8080

# View logs
sudo journalctl -u viam-agent -f
```

### Phone App Installation
```bash
# Install APK via ADB
adb install app-release.apk

# Grant permissions
adb shell pm grant com.example.viam_pixel4a_sensors android.permission.CAMERA
adb shell pm grant com.example.viam_pixel4a_sensors android.permission.RECORD_AUDIO
adb shell pm grant com.example.viam_pixel4a_sensors android.permission.ACCESS_FINE_LOCATION

# View app logs
adb logcat -s ViamPiApp
adb logcat -s FlutterViam
```

---

## 🔌 Connection Sequence

### 1. Network Connection
```bash
# Test connectivity (from phone)
ping 192.168.42.116
telnet 192.168.42.116 8080

# Test connectivity (from Pi)
ping 192.168.42.129
```

### 2. Viam Service Check
```bash
# Verify Viam is listening
sudo netstat -tlnp | grep 8080
sudo ss -tlnp | grep 8080

# Health check
curl http://192.168.42.116:8080/api/v1/health
```

### 3. App Connection
1. Launch app on phone
2. Auto-discovers Pi at 192.168.42.116
3. Establishes gRPC connection on port 8080
4. Starts streaming sensor data

---

## 📊 Data Stream Configuration

### Sensor Specifications
| Sensor | Rate | Data Type | Size |
|--------|------|-----------|------|
| IMU | 100Hz | 6DOF (acc+gyro) | ~50 bytes/sample |
| Camera | 30fps | JPEG images | ~50KB/frame |
| Audio | 16kHz | PCM audio | ~32KB/s |
| GPS | 1Hz | Lat/Lon/Alt | ~20 bytes/reading |

### gRPC Message Formats
```protobuf
// IMU Data
message IMUReading {
  double acc_x, acc_y, acc_z
  double gyro_x, gyro_y, gyro_z
  int64 timestamp_ms
}

// Camera Frame
message CameraFrame {
  bytes image_data
  int32 width, height
  string format
  int64 timestamp
}

// Audio Chunk
message AudioChunk {
  bytes audio_data
  int32 sample_rate
  int32 channels
}
```

---

## 🛠️ Troubleshooting Commands

### Network Issues
```bash
# Check connection
ping 192.168.42.116
traceroute 192.168.42.116

# Check ports
nmap -p 8080 192.168.42.116
nc -zv 192.168.42.116 8080

# Restart networking
sudo systemctl restart networking
sudo dhclient wlan0
```

### Viam Issues
```bash
# Restart Viam
sudo systemctl restart viam-agent

# Check logs
sudo journalctl -u viam-agent -n 100

# Verify components
curl http://localhost:8080/api/v1/components

# Test API
curl http://localhost:8080/api/v1/health
```

### Phone Issues
```bash
# Clear app data
adb shell pm clear com.example.viam_pixel4a_sensors

# Reinstall app
adb uninstall com.example.viam_pixel4a_sensors
adb install app-release.apk

# Check permissions
adb shell dumpsys package com.example.viam_pixel4a_sensors | grep permission
```

---

## ⚙️ Configuration Files

### Viam Agent Config
```bash
# Location: /etc/viam-agent.json
{
  "network": {
    "bind_address": "0.0.0.0:8080"
  },
  "logging": {
    "level": "info"
  }
}
```

### Android App Config
```dart
// Main configuration in lib/providers/pi_connection_provider.dart
final possibleAddresses = [
  '192.168.42.116', // Your Pi IP
  '10.10.10.67',   // USB tethering backup
];
```

---

## 🔍 Diagnostic Commands

### System Resources
```bash
# Pi performance
htop
iotop -o
nethogs wlan0

# Phone battery
adb shell dumpsys battery

# Network statistics
iftop -i wlan0
```

### Real-time Monitoring
```bash
# Pi logs live
sudo journalctl -u viam-agent -f

# Phone logs live
adb logcat -s ViamPiApp | tee phone_logs.txt

# Network traffic
tcpdump -i wlan0 port 8080
```

---

## 📋 Daily Operations Checklist

### Pre-Flight Check
```bash
# On Pi
sudo systemctl status viam-agent
curl http://localhost:8080
ping 192.168.42.129

# On Phone
# 1. Open app
# 2. Check all permissions
# 3. Verify connection status is green
# 4. Confirm sensors are active
```

### Post-Flight Check
```bash
# Export logs
adb logcat -d > phone_$(date +%Y%m%d).log
sudo journalctl -u viam-agent --since "1 hour ago" > pi_$(date +%Y%m%d).log

# Check system status
df -h
free -h
uptime
```

---

## 🚨 Emergency Recovery

### Complete Reset
```bash
# On Pi - reset Viam
sudo systemctl stop viam-agent
sudo systemctl reset-failed viam-agent
sudo systemctl start viam-agent

# On Phone - reset app
adb uninstall com.example.viam_pixel4a_sensors
adb install app-release.apk

# Network reset
sudo systemctl restart networking
adb shell svc wifi disable && adb shell svc wifi enable
```

### USB Tethering Fallback
```bash
# Enable USB tethering on phone
# Settings -> Network -> USB Tethering -> Enable

# Pi should get IP 10.10.10.67
# Phone should get IP 10.10.10.1

# Test USB connection
ping 10.10.10.67
```

---

## 📞 Support Commands

### Generate Support Bundle
```bash
# Create support package
mkdir support_$(date +%Y%m%d)
cd support_$(date +%Y%m%d)

# Pi diagnostics
sudo journalctl -u viam-agent > pi_agent.log
ps aux > pi_processes.log
netstat -tlnp > pi_network.log
df -h > pi_disk.log
free -h > pi_memory.log

# Phone diagnostics
adb logcat -d > phone.log
adb shell dumpsys battery > phone_battery.log
adb shell dumpsys connectivity > phone_network.log

# Package everything
tar -czf viam_support_$(date +%Y%m%d).tar.gz *
```

---

## 🎯 Performance Tuning

### Optimize for Speed
```bash
# Increase process priority
sudo renice -10 $(pgrep viam-agent)

# Network priority
sudo tc qdisc add dev wlan0 root handle 1: htb default 12
sudo tc class add dev wlan0 parent 1: classid 1:12 htb rate 1000mbit

# Disable unnecessary services
sudo systemctl stop bluetooth
sudo systemctl stop cups
```

### Optimize for Battery
```dart
// In app - reduce sample rates
final sensorConfig = {
  'imu_rate': 50,        // Lower from 100Hz
  'camera_fps': 15,      // Lower from 30fps
  'audio_sample_rate': 8000, // Lower from 16kHz
};
```

---

## 📊 Key Metrics

### Expected Performance
| Metric | Target | Acceptable Range |
|--------|--------|------------------|
| Connection Latency | <10ms | <50ms |
| IMU Update Rate | 100Hz | 50-200Hz |
| Camera FPS | 30fps | 15-30fps |
| Audio Latency | <20ms | <100ms |
| Battery Life | 4+ hours | 2+ hours |

### Monitoring Commands
```bash
# Measure latency
ping -c 10 192.168.42.116

# Check data rates
iftop -t -s 10

# Monitor CPU
top -p $(pgrep viam-agent)

# Check memory
free -h && cat /proc/meminfo | grep MemAvailable
```

---

**🎯 Keep this cheat sheet handy for quick reference during setup and operation!**

All essential ports, IPs, and commands are consolidated here for fast access.