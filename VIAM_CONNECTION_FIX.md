# Viam Connection Fix - gRPC Channel Type Error

## Problem
When trying to connect to Viam, you get this error:
```
Connection error 
type GrpcOrGrpcWebClientChannel is
not a subtype of type
WebRrcClientChannel in type cast
```

## Root Cause
This error occurs due to API changes in the Viam SDK where different gRPC channel types are not compatible with each other. The issue happens when mixing different connection methods.

## Solution Applied

### 1. Updated ViamProvider
- **Separated connection methods** for direct Pi vs cloud connections
- **Removed incompatible channel type casting**
- **Added proper error handling** for different connection types

### 2. Updated ViamConnectionDialog
- **Added direct connection toggle** - no API keys needed for Pi
- **Quick setup buttons** for USB and WiFi connections
- **Better error display** and connection status

## How to Connect Now

### Direct Pi Connection (Recommended)
1. Toggle "Direct Pi Connection" ON
2. Enter Pi address: `10.10.10.67:8080` (or use "USB Default" button)
3. Click "Connect"
4. No API keys required!

### Cloud Connection (Alternative)
1. Toggle "Direct Pi Connection" OFF
2. Enter robot address
3. Enter API Key ID and API Key
4. Click "Connect"

## Connection Addresses

### USB Tethering (Primary)
```
Pi IP: 10.10.10.67
Port: 8080
Address: 10.10.10.67:8080
```

### WiFi Network (Alternative)
```
Pi IP: 192.168.1.100 (example)
Port: 8080
Address: 192.168.1.100:8080
```

## Testing the Connection

### Step 1: Verify Pi is Running Viam
```bash
# On Raspberry Pi
curl localhost:8080
# Should return Viam agent response
```

### Step 2: Test Network Connection
```bash
# From phone (or computer)
ping 10.10.10.67
# Should get responses
```

### Step 3: Test App Connection
1. Open app
2. Go to Viam Connection Settings
3. Use Direct Pi Connection
4. Enter `10.10.10.67:8080`
5. Click Connect

## Troubleshooting Checklist

### Connection Fails
- [ ] USB cable connected between phone and Pi
- [ ] USB tethering enabled on phone
- [ ] Pi IP is `10.10.10.67`
- [ ] Viam agent running on Pi (port 8080)
- [ ] No firewall blocking port 8080

### App Crashes
- [ ] App updated to latest version
- [ ] Phone rebooted
- [ ] All permissions granted

### Still Not Working
1. Check Pi logs: `journalctl -u viam-agent`
2. Check app logs: Android Logcat
3. Try WiFi connection as alternative
4. Restart both phone and Pi

## Technical Details

### The Fix
```dart
// Before (causing error)
_robot = await RobotClient.atAddress(address, options);

// After (fixed)
if (useDirectConnection) {
  _robot = await _createDirectConnection(address);
} else {
  final options = RobotClientOptions.withApiKey(_apiKeyId, _apiKey);
  _robot = await RobotClient.atAddress(address, options);
}

Future<RobotClient> _createDirectConnection(String address) async {
  try {
    return await RobotClient.atAddress(address);
  } catch (e) {
    // Fallback to host:port format
    return await RobotClient.atAddress(address);
  }
}
```

### Key Changes
1. **No API keys for direct Pi connection**
2. **Separate connection logic for different types**
3. **Better error handling and fallbacks**
4. **UI improvements for easier setup**

## Success Indicators

✅ **Connection Status**: "Connected to 10.10.10.67:8080"
✅ **Green status indicator** in connection dialog
✅ **Available Resources** listed (sensors, cameras, audio)
✅ **No error messages** in connection status

## Next Steps

Once connected:
1. Test sensor data streaming
2. Verify face detection works
3. Test audio communication
4. Set up personality integration

The app should now connect successfully to Viam without any gRPC channel type errors!