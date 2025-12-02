import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_display_provider.dart';

class FullScreenEyesScreen extends StatefulWidget {
  const FullScreenEyesScreen({super.key});

  @override
  State<FullScreenEyesScreen> createState() => _FullScreenEyesScreenState();
}

class _FullScreenEyesScreenState extends State<FullScreenEyesScreen> {
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for full screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore portrait orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Consumer<EmotionDisplayProvider>(
          builder: (context, emotionProvider, child) {
            return Stack(
              children: [
                // Main eye display - full screen
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left eye - Cars movie style
                      _buildCarsEye(
                        x: emotionProvider.eyeX,
                        y: emotionProvider.eyeY,
                        openness: emotionProvider.eyeOpenness,
                        pupilSize: emotionProvider.pupilSize,
                        emotion: emotionProvider.currentEmotion,
                        isLeftEye: true,
                        size: MediaQuery.of(context).size.height * 0.6,
                      ),
                      
                      // Right eye - Cars movie style
                      _buildCarsEye(
                        x: emotionProvider.eyeX,
                        y: emotionProvider.eyeY,
                        openness: emotionProvider.eyeOpenness,
                        pupilSize: emotionProvider.pupilSize,
                        emotion: emotionProvider.currentEmotion,
                        isLeftEye: false,
                        size: MediaQuery.of(context).size.height * 0.6,
                      ),
                    ],
                  ),
                ),

                // Control overlay (appears on tap)
                if (_showControls)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top controls
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back button
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                
                                // Emotion selector
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: DropdownButton<Emotion>(
                                    value: emotionProvider.currentEmotion,
                                    dropdownColor: Colors.black87,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                    items: Emotion.values.map((emotion) {
                                      return DropdownMenuItem(
                                        value: emotion,
                                        child: Text(
                                          emotion.name.toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (emotion) {
                                      if (emotion != null) {
                                        emotionProvider.setEmotion(emotion);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom controls
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                // Manual eye position control
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.adjust,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: Colors.white,
                                          overlayColor: Colors.white24,
                                        ),
                                        child: Slider(
                                          value: emotionProvider.eyeX,
                                          onChanged: (value) => emotionProvider.setEyePosition(
                                            value,
                                            emotionProvider.eyeY,
                                          ),
                                          min: -1.0,
                                          max: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Steering control
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.navigation,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Colors.orange,
                                          inactiveTrackColor: Colors.orange.withOpacity(0.24),
                                          thumbColor: Colors.orange,
                                          overlayColor: Colors.orange.withOpacity(0.24),
                                        ),
                                        child: Slider(
                                          value: emotionProvider.steeringAngle,
                                          onChanged: emotionProvider.setSteeringAngle,
                                          min: -45.0,
                                          max: 45.0,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${emotionProvider.steeringAngle.toInt()}°',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Quick emotion buttons
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _quickEmotionButton(Emotion.happy, '😊'),
                                    _quickEmotionButton(Emotion.sad, '😢'),
                                    _quickEmotionButton(Emotion.angry, '😠'),
                                    _quickEmotionButton(Emotion.surprised, '😲'),
                                    _quickEmotionButton(Emotion.sleepy, '😴'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Instructions hint
                if (!_showControls)
                  const Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Tap anywhere for controls',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _quickEmotionButton(Emotion emotion, String emoji) {
    return GestureDetector(
      onTap: () {
        Provider.of<EmotionDisplayProvider>(context, listen: false)
            .setEmotion(emotion);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCarsEye({
    required double x,
    required double y,
    required double openness,
    required double pupilSize,
    required Emotion emotion,
    required bool isLeftEye,
    required double size,
  }) {
    return Container(
      width: size,
      height: size * 0.7, // Cars eyes are wider than tall
      child: Stack(
        children: [
          // Eye white - oval shape like Cars movie
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(5, 5),
                ),
              ],
            ),
          ),

          // Iris - Cars movie style with more detail
          Positioned(
            left: (size / 2) + (x * size * 0.15) - (size * 0.12),
            top: (size * 0.35) + (y * size * 0.1) - (size * 0.12),
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _getEmotionColor(emotion).withOpacity(0.9),
                    _getEmotionColor(emotion).withOpacity(0.6),
                    _getEmotionColor(emotion).withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getEmotionColor(emotion).withOpacity(0.8),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Inner iris detail
                  Positioned(
                    left: size * 0.02,
                    top: size * 0.02,
                    child: Container(
                      width: size * 0.08,
                      height: size * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pupil - Cars movie style
          Positioned(
            left: (size / 2) + (x * size * 0.15) - (size * 0.08 * pupilSize),
            top: (size * 0.35) + (y * size * 0.1) - (size * 0.08 * pupilSize),
            child: Container(
              width: size * 0.16 * pupilSize,
              height: size * 0.16 * pupilSize,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          // Eye lid overlay for blinking/closing - Cars movie style
          if (openness < 1.0)
            Positioned.fill(
              child: ClipPath(
                clipper: _CarsEyeLidClipper(openness: openness),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(size * 0.4),
                  ),
                ),
              ),
            ),

          // Eye highlight for glassy effect
          Positioned(
            left: size * 0.15,
            top: size * 0.15,
            child: Container(
              width: size * 0.12,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return Colors.lightBlue;
      case Emotion.sad:
        return Colors.blueGrey;
      case Emotion.angry:
        return Colors.red;
      case Emotion.surprised:
        return Colors.deepPurple;
      case Emotion.curious:
        return Colors.amber;
      case Emotion.focused:
        return Colors.teal;
      case Emotion.sleepy:
        return Colors.indigo;
      case Emotion.excited:
        return Colors.orange;
      case Emotion.confused:
        return Colors.brown;
      case Emotion.neutral:
      default:
        return Colors.blue;
    }
  }
}

class _CarsEyeLidClipper extends CustomClipper<Path> {
  final double openness;

  const _CarsEyeLidClipper({required this.openness});

  @override
  Path getClip(Size size) {
    final path = Path();
    final lidHeight = size.height * (1.0 - openness);
    
    // Create curved eyelid like Cars movie
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, lidHeight),
        Radius.circular(size.width * 0.4),
      ),
    );
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}