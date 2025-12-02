# Pixel 4a Robot Eyes & Sensors - Quick Start Guide

## What This Does
Turn your Google Pixel 4a into a robot's eyes and brain! The phone provides:
- **Emotional Eyes**: Animated eyes that show robot feelings
- **Face Detection**: See and track people 
- **Motion Sensors**: Replace expensive IMU sensors
- **Voice Interface**: Talk and listen to your robot
- **Direct Viam Integration**: Works seamlessly with Viam robotics

## Quick Setup (10 Minutes)

### Step 1: Install & Connect
1. Install the app on your Pixel 4a
2. Connect phone to Raspberry Pi with USB cable
3. Enable USB tethering on phone (Settings → Network → USB tethering)
4. Phone IP: `10.10.10.1`, Pi IP: `10.10.10.67`

### Step 2: Grant Permissions
- Camera (for face detection)
- Microphone (for voice commands) 
- Location (for sensors)
- Storage (for recordings)

### Step 3: Start the App
1. Open "Viam Pi Integration" app
2. Tap "Test All" to verify everything works
3. Go to Settings (gear icon) to configure IP addresses if needed

## Using the Eyes Display

### Normal Mode
- Eyes appear in the app window
- Shows emotions based on robot state
- Tracks faces when people are detected

### Full-Screen Mode 
- Tap the eyes or go to Full Screen Eyes
- Eyes fill entire phone screen
- Perfect for mounting as robot eyes
- Tap screen to show/hide controls

### Emotion States
```
😊 Happy    - Friendly, engaged
😢 Sad      - Disappointed 
😠 Angry    - Frustrated, alert
😮 Surprised- Alert, discovery  
😐 Neutral  - Default, listening
🤔 Curious  - Inquisitive
🎯 Focused  - Concentrating
😴 Sleepy   - Low power
🤉 Excited  - High energy
😕 Confused - Uncertain
```

## Robot Integration

### For Viam Users
The phone automatically creates these components:
- `phone_imu` - Motion sensor (100Hz data)
- `phone_camera` - Face detection camera
- `phone_audio` - Microphone and speaker
- `phone_display` - Emotional eye display

### Basic Robot Code (Python)
```python
import asyncio
from viam.robot.client import RobotClient

async def main():
    robot = await RobotClient.at_address('10.10.10.67:8080')
    
    # Set robot emotion
    await robot.phone_display.set_emotion('happy')
    
    # Get sensor data
    imu_data = await robot.phone_imu.get_readings()
    faces = await robot.phone_camera.get_faces()
    
    # Make robot speak
    await robot.phone_audio.speak('Hello, I am awake!')
    
    await robot.close()

asyncio.run(main())
```

## Personality Integration

### Voice Response Loop
```python
async def conversation_loop():
    while True:
        # Show listening eyes
        await robot.phone_display.set_emotion('curious')
        
        # Listen for voice
        audio = await robot.phone_audio.listen(timeout=5)
        
        if audio:
            # Process and respond
            response = process_voice(audio)
            await robot.phone_display.set_emotion('focused')
            await robot.phone_audio.speak(response.text)
            await robot.phone_display.set_emotion(response.emotion)
```

### Sensor-Based Reactions
```python
async def sensor_reactions():
    # React to movement
    imu = await robot.phone_imu.get_readings()
    if imu['acceleration']['z'] > 9.0:  # Falling
        await robot.phone_display.set_emotion('surprised')
    
    # React to faces
    faces = await robot.phone_camera.get_faces()
    if faces and faces[0].smiling > 0.7:
        await robot.phone_display.set_emotion('happy')
```

## Mounting as Robot Eyes

### Physical Setup
1. Mount phone horizontally on robot head
2. Position screen forward-facing
3. Ensure USB cable reaches Raspberry Pi
4. Consider phone holder or 3D printed mount

### Display Settings
- Use Full Screen Eyes mode
- Set phone to stay awake (Settings → Display → Screen timeout → Never)
- Disable auto-brightness for consistent appearance
- Consider portrait orientation for taller eye display

### Power Management
- Phone draws ~500mA during normal use
- Consider external battery backup for long operation
- USB tethering charges phone while connected
- Monitor battery level in app status

## Troubleshooting

### Connection Issues
- **Phone not connecting**: Check USB cable, enable tethering
- **Wrong IP addresses**: Use app Settings to configure
- **Intermittent connection**: Check USB cable quality

### Sensor Problems  
- **No face detection**: Grant camera permission, good lighting
- **No sensor data**: Grant location permission, restart app
- **Audio not working**: Grant microphone permission, check volume

### Display Issues
- **Eyes not showing**: App must be in foreground
- **Full screen not working**: Check phone orientation settings
- **Emotions stuck**: Restart app, check Viam connection

## Advanced Features

### Custom Eye Styles
- Cars movie style (oval, detailed iris)
- Robot style (circular, mechanical)
- Cartoon style (expressive, animated)

### Network Options
- USB tethering (primary, most stable)
- WiFi network (alternative, less reliable)  
- Hotspot mode (for testing)

### Data Streams
- IMU: 100Hz accelerometer + gyroscope
- Camera: 30fps face detection with emotion
- Audio: 16kHz voice input/output
- Display: 60fps animated eyes

## Support & Resources

### Documentation
- Full technical guide: `VIAM_PIXEL_4A_CHEAT_SHEET.md`
- API reference in app source code
- Viam documentation for component integration

### Community
- Share your robot personality configurations
- Request new emotion states or features
- Report bugs or connection issues

### Development
- App built with Flutter
- Open source on GitHub
- Easy to customize and extend

---

**Ready to bring your robot to life?** 

1. Set up the phone and Pi connection
2. Install the app and grant permissions  
3. Mount phone as robot eyes
4. Code your personality responses
5. Watch your robot come alive!

For detailed technical integration, see the full cheat sheet with all API endpoints and hooks.