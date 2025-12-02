# Personality Integration with Pixel 4a - Technical Guide

## Complete Integration Architecture

This guide explains how to integrate your AI personality with the Pixel 4a robot eyes and sensors system.

## System Architecture Diagram

```
┌─────────────────┐    USB     ┌─────────────────┐    WiFi/Eth    ┌─────────────────┐
│   Pixel 4a      │ ◄───────► │ Raspberry Pi    │ ◄────────────► │   Your Robot    │
│                 │            │                 │                │                 │
│ ┌─────────────┐ │            │ ┌─────────────┐ │                │ ┌─────────────┐ │
│ │   Flutter   │ │            │ │  Viam Agent │ │                │ │  Robot Code │ │
│ │     App     │ │            │ │   (8080)    │ │                │ │             │ │
│ └─────────────┘ │            │ └─────────────┘ │                │ └─────────────┘ │
│        │        │            │        │        │                │        │        │
│ ┌─────────────┐ │            │ ┌─────────────┐ │                │ ┌─────────────┐ │
│ │ Sensors     │ │            │ │   gRPC      │ │                │ │ Personality │ │
│ │ Camera      │ │◄──────────►│ │   Server    │ │◄──────────────►│ │    Engine   │ │
│ │ Audio       │ │            │ │             │ │                │ │             │ │
│ │ Display     │ │            │ └─────────────┘ │                │ └─────────────┘ │
└─────────────────┘            └─────────────────┘                └─────────────────┘
```

## 1. Data Flow Architecture

### Sensor → Personality Pipeline
```
Phone Sensors → Viam Agent → Robot Code → Personality Engine → Phone Display
     ↓               ↓              ↓              ↓                ↓
  IMU Data      gRPC Stream    Python/JS    Decision Logic    Eye Emotions
Face Data      WebSocket      Processing   State Machine     Animations  
Audio Data     Events         AI Logic     Response Gen       Voice Output
```

### Bidirectional Communication
```python
# Robot → Phone (Control Flow)
personality_decision → robot_code → viam_agent → phone_app → display_change

# Phone → Robot (Sensor Flow)  
phone_sensors → app_processing → viam_agent → robot_code → personality_input
```

## 2. Complete API Reference

### Phone Display API (Emotional Eyes)

#### Emotion Control
```python
# Set immediate emotion
await robot.phone_display.set_emotion(
    emotion="happy",           # Emotion enum value
    intensity=0.8,            # 0.0-1.0 strength
    duration_ms=2000,         # Auto-revert after N ms
    transition="smooth"       # "smooth" | "instant" | "fade"
)

# Complex emotion sequence
await robot.phone_display.set_emotion_sequence([
    {"emotion": "surprised", "duration": 500},
    {"emotion": "confused", "duration": 1000}, 
    {"emotion": "happy", "duration": 2000}
])
```

#### Eye Movement Control
```python
# Direct positioning (normalized coordinates 0.0-1.0)
await robot.phone_display.set_eye_position(
    left_x=0.5, left_y=0.5,      # Left eye center
    right_x=0.5, right_y=0.5,    # Right eye center  
    smooth=True,                 # Smooth transition
    look_at_point=True           # Calculate gaze angle
)

# Look at detected person
await robot.phone_display.look_at_person(
    face_id="face_001",          # From face detection
    attention_duration=3.0,      # Seconds to maintain gaze
    natural_movement=True        # Human-like eye movements
)

# Steering visualization (for robot movement)
await robot.phone_display.set_steering(
    angle=-30,                   # Degrees (-45 to +45)
    speed=0.8,                   # 0.0-1.0 movement speed
    show_direction=True          # Display steering arrows
)
```

#### Animation Controls
```python
# Blinking patterns
await robot.phone_display.set_blinking(
    enabled=True,
    interval_ms=3000,           # Between blinks
    duration_ms=150,            # Blink speed  
    random_variance=0.2         # Natural timing variation
)

# Personality-based movements
await robot.phone_display.set_personality_mode(
    personality="friendly",      # "friendly" | "robotic" | "playful"
    responsiveness=0.8,         # Reaction speed 0.0-1.0
    expressiveness=0.9,         # Emotional range 0.0-1.0
    eye_contact=True            # Maintain eye contact with humans
)

# Special animations
await robot.phone_display.play_animation(
    animation="thinking",       # "thinking" | "searching" | "excited"
    duration_ms=2000,
    loop=False
)
```

### Sensor APIs

#### IMU/Motion Sensors
```python
# Get current readings
imu_data = await robot.phone_imu.get_readings()
# Returns: {
#   "acceleration": {"x": 0.1, "y": -0.2, "z": 9.8},
#   "gyroscope": {"x": 0.01, "y": 0.02, "z": 0.00},
#   "orientation": {"pitch": 5.2, "roll": -1.1, "yaw": 180.0},
#   "timestamp": "2024-01-01T12:00:00Z"
# }

# Stream real-time data (100Hz)
async for imu_reading in robot.phone_imu.stream_readings():
    # Process high-frequency sensor data
    robot.update_balance(imu_reading)
    
# Configure sensor settings
await robot.phone_imu.configure(
    frequency_hz=100,            # Sampling rate
    filters=["low_pass", "calibration"],
    sensitivity="high"
)
```

#### Face Detection
```python
# Get detected faces
faces = await robot.phone_camera.get_faces()
# Returns: [
#   {
#     "id": "face_001",
#     "bounding_box": {"x": 100, "y": 150, "width": 200, "height": 250},
#     "confidence": 0.95,
#     "smiling_probability": 0.8,
#     "head_pose": {"yaw": 5.0, "pitch": -2.0, "roll": 1.0},
#     "eye_openness": {"left": 0.9, "right": 0.8},
#     "timestamp": "2024-01-01T12:00:00Z"
#   }
# ]

# Stream face detection events
async for face_event in robot.phone_camera.stream_faces():
    if face_event["faces"]:
        primary_face = face_event["faces"][0]
        await robot.phone_display.look_at_person(primary_face["id"])

# Configure face detection
await robot.phone_camera.configure_face_detection(
    detection_mode="accurate",   # "fast" | "accurate" | "continuous"
    min_face_size=50,           # Minimum pixels
    emotion_detection=True,
    tracking_enabled=True
)
```

#### Audio/Voice Interface
```python
# Speech synthesis
await robot.phone_audio.speak(
    text="Hello, I'm your robot assistant!",
    voice="default",            # Voice preset
    speed=1.0,                  # Speech rate 0.5-2.0
    pitch=1.0,                  # Voice pitch 0.5-2.0
    volume=0.8                  # Volume 0.0-1.0
)

# Voice recognition with timeout
audio_data = await robot.phone_audio.listen(
    timeout_seconds=5.0,
    silence_threshold=0.1,
    max_duration=30.0
)
# Returns: {
#   "audio_data": bytes,
#   "duration_ms": 2500,
#   "confidence": 0.85,
#   "transcription": "Hello robot"  # If speech-to-text enabled
# }

# Continuous audio monitoring
async for audio_chunk in robot.phone_audio.stream_audio():
    voice_detected = await personality.process_audio(audio_chunk)
    if voice_detected:
        await robot.phone_display.set_emotion("curious")

# Audio configuration
await robot.phone_audio.configure(
    sample_rate=16000,          # Hz
    channels=1,                 # Mono
    noise_reduction=True,
    echo_cancellation=True
)
```

## 3. Personality Integration Patterns

### State Machine Architecture
```python
class RobotPersonality:
    def __init__(self, robot):
        self.robot = robot
        self.current_state = "idle"
        self.emotion_history = []
        self.attention_target = None
        
    async def process_sensors(self, sensor_data):
        """Process incoming sensor data and update personality state"""
        
        # Face detection response
        if sensor_data.get("faces"):
            face = sensor_data["faces"][0]
            await self.handle_face_detected(face)
            
        # IMU response (robot movement)
        if sensor_data.get("imu"):
            await self.handle_movement(sensor_data["imu"])
            
        # Audio response
        if sensor_data.get("audio"):
            await self.handle_voice_input(sensor_data["audio"])
    
    async def handle_face_detected(self, face):
        """React to detected human face"""
        self.attention_target = face["id"]
        
        # Look at the person
        await self.robot.phone_display.look_at_person(face["id"])
        
        # Emotional response based on expression
        if face.get("smiling_probability", 0) > 0.7:
            await self.robot.phone_display.set_emotion("happy")
            self.current_state = "engaged"
        elif face.get("head_pose", {}).get("yaw", 0) > 45:
            await self.robot.phone_display.set_emotion("confused")
            self.current_state = "uncertain"
        else:
            await self.robot.phone_display.set_emotion("curious")
            self.current_state = "attentive"
    
    async def handle_movement(self, imu_data):
        """React to robot movement/inclination"""
        accel = imu_data["acceleration"]
        
        # Robot is tilting significantly
        if abs(accel["x"]) > 2.0 or abs(accel["y"]) > 2.0:
            await self.robot.phone_display.set_emotion("surprised")
            await self.robot.phone_display.eyes_wide()
            
        # Robot is stationary but tilted
        elif accel["z"] < 8.0:
            await self.robot.phone_display.set_emotion("confused")
            self.current_state = "off_balance"
    
    async def handle_voice_input(self, audio_data):
        """Process voice commands and respond"""
        # Show listening state
        await self.robot.phone_display.set_emotion("curious")
        await self.robot.phone_display.start_listening_animation()
        
        # Process speech
        transcription = await self.speech_to_text(audio_data)
        response = await self.generate_response(transcription)
        
        # Show thinking state
        await self.robot.phone_display.set_emotion("focused")
        await asyncio.sleep(0.5)  # Natural pause
        
        # Respond
        await self.robot.phone_audio.speak(response["text"])
        await self.robot.phone_display.set_emotion(response["emotion"])
        
        self.current_state = "responding"
```

### Emotional Response System
```python
class EmotionalResponses:
    """Map personality states to phone display emotions"""
    
    EMOTION_MAP = {
        "greeting": {"emotion": "happy", "intensity": 0.9, "animation": "welcoming"},
        "thinking": {"emotion": "focused", "intensity": 0.7, "animation": "thinking"},
        "confused": {"emotion": "confused", "intensity": 0.6, "animation": "looking_around"},
        "excited": {"emotion": "excited", "intensity": 1.0, "animation": "bouncing"},
        "sleepy": {"emotion": "sleepy", "intensity": 0.5, "animation": "drooping"},
        "alert": {"emotion": "surprised", "intensity": 0.8, "animation": "wide_eyes"},
        "attentive": {"emotion": "curious", "intensity": 0.7, "animation": "alert"},
        "sad": {"emotion": "sad", "intensity": 0.6, "animation": "drooping"},
        "angry": {"emotion": "angry", "intensity": 0.8, "animation": "intense"},
    }
    
    @classmethod
    async def trigger_response(cls, robot, response_type, custom_params=None):
        """Trigger a predefined emotional response"""
        response = cls.EMOTION_MAP.get(response_type, {"emotion": "neutral"})
        
        # Merge custom parameters
        if custom_params:
            response.update(custom_params)
            
        # Apply to robot
        await robot.phone_display.set_emotion(
            emotion=response["emotion"],
            intensity=response.get("intensity", 0.7),
            transition="smooth"
        )
        
        # Play associated animation
        if "animation" in response:
            await robot.phone_display.play_animation(
                animation=response["animation"],
                duration_ms=2000
            )
```

### Conversation Integration
```python
class ConversationManager:
    """Manage voice conversations with personality integration"""
    
    def __init__(self, robot, personality):
        self.robot = robot
        self.personality = personality
        self.conversation_state = "idle"
        
    async def start_conversation_loop(self):
        """Main conversation interaction loop"""
        while True:
            try:
                # Show ready state
                await self.robot.phone_display.set_emotion("neutral")
                await self.robot.phone_display.eyes_forward()
                
                # Listen for voice input
                audio_data = await self.robot.phone_audio.listen(timeout=10)
                
                if audio_data:
                    await self.handle_voice_interaction(audio_data)
                else:
                    # No voice detected, show waiting state
                    await self.robot.phone_display.set_emotion("curious")
                    await asyncio.sleep(2)
                    
            except Exception as e:
                await self.robot.phone_display.set_emotion("confused")
                await asyncio.sleep(1)
    
    async def handle_voice_interaction(self, audio_data):
        """Process complete voice interaction cycle"""
        
        # Phase 1: Listening
        await self.robot.phone_display.set_emotion("curious")
        await self.robot.phone_display.start_listening_animation()
        
        # Phase 2: Processing  
        await self.robot.phone_display.set_emotion("focused")
        await self.robot.phone_display.eyes_look_up()  # Thinking pose
        
        transcription = await self.speech_to_text(audio_data)
        intent = await self.analyze_intent(transcription)
        response = await self.generate_response(intent)
        
        # Phase 3: Responding
        await self.robot.phone_display.set_emotion(response["emotion"])
        await self.robot.phone_display.eyes_forward()
        
        await self.robot.phone_audio.speak(response["text"])
        
        # Phase 4: Follow-up
        if response.get("expect_reply"):
            await self.robot.phone_display.set_emotion("curious")
            await self.robot.phone_display.subtle_blinking()
        else:
            await self.robot.phone_display.set_emotion("neutral")
            await asyncio.sleep(2)
```

## 4. Integration Setup Instructions

### Step 1: Robot Code Integration
```python
# main_robot.py
import asyncio
from viam.robot.client import RobotClient
from personality_engine import RobotPersonality
from conversation_manager import ConversationManager

async def main():
    # Connect to Viam robot
    robot = await RobotClient.at_address('10.10.10.67:8080')
    
    # Initialize personality
    personality = RobotPersonality(robot)
    await personality.initialize()
    
    # Start conversation manager
    conversation = ConversationManager(robot, personality)
    conversation_task = asyncio.create_task(conversation.start_conversation_loop())
    
    # Start sensor monitoring
    sensor_task = asyncio.create_task(personality.start_sensor_monitoring())
    
    try:
        await asyncio.gather(conversation_task, sensor_task)
    except KeyboardInterrupt:
        print("Shutting down robot...")
    finally:
        await robot.close()

if __name__ == "__main__":
    asyncio.run(main())
```

### Step 2: Viam Configuration
```json
{
  "components": [
    {
      "name": "phone_imu",
      "type": "movement_sensor",
      "model": "phone_imu",
      "attributes": {
        "data_frequency_hz": 100,
        "coordinate_system": "right_hand"
      }
    },
    {
      "name": "phone_camera", 
      "type": "camera",
      "model": "phone_face_detection",
      "attributes": {
        "face_detection_enabled": true,
        "emotion_detection": true,
        "fps": 30,
        "resolution": "720p"
      }
    },
    {
      "name": "phone_audio",
      "type": "audio_input",
      "model": "phone_microphone", 
      "attributes": {
        "sample_rate": 16000,
        "channels": 1,
        "noise_reduction": true
      }
    },
    {
      "name": "phone_display",
      "type": "display",
      "model": "phone_emotion_display",
      "attributes": {
        "emotion_states": ["happy", "sad", "angry", "surprised", "neutral", "curious", "focused", "sleepy", "excited", "confused"],
        "animation_framerate": 60
      }
    }
  ]
}
```

### Step 3: Phone App Configuration
1. Set network to USB tethering mode
2. Configure Pi IP: `10.10.10.67`
3. Enable all sensor permissions
4. Set display to full-screen eyes mode
5. Test all components with "Test All" button

## 5. Advanced Integration Features

### Custom Emotion Creation
```python
# Create custom emotion sequences
await robot.phone_display.create_custom_emotion(
    name="playful",
    sequence=[
        {"time": 0, "emotion": "happy", "intensity": 0.5},
        {"time": 500, "emotion": "excited", "intensity": 0.8}, 
        {"time": 1500, "emotion": "happy", "intensity": 0.6}
    ]
)
```

### Multi-Person Attention
```python
# Track multiple faces
async def handle_multiple_faces(faces):
    if len(faces) == 1:
        # Focus on single person
        await robot.phone_display.look_at_person(faces[0]["id"])
        await robot.phone_display.set_emotion("engaged")
    elif len(faces) > 1:
        # Multiple people - show social awareness
        await robot.phone_display.set_emotion("curious")
        await robot.phone_display.eyes_scan_between_people(faces)
        await robot.phone_audio.speak("Oh, we have company!")
```

### Context-Aware Responses
```python
class ContextAwarePersonality:
    def __init__(self):
        self.time_of_day = datetime.now().hour
        self.environment_noise = 0.0
        self.recent_interactions = []
    
    async def contextual_greeting(self):
        if 6 <= self.time_of_day <= 12:
            await self.robot.phone_display.set_emotion("happy")
            await self.robot.phone_audio.speak("Good morning! Ready to start our day?")
        elif 12 <= self.time_of_day <= 18:
            await self.robot.phone_display.set_emotion("focused") 
            await self.robot.phone_audio.speak("Good afternoon! What can we accomplish today?")
        else:
            await self.robot.phone_display.set_emotion("sleepy")
            await self.robot.phone_audio.speak("Good evening... time to wind down?")
```

This technical guide provides everything needed to integrate a sophisticated AI personality with the Pixel 4a robot eyes and sensors system. The combination creates a truly interactive and expressive robot companion.