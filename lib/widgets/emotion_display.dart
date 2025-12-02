import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_display_provider.dart';
import '../screens/full_screen_eyes.dart';

class EmotionDisplay extends StatelessWidget {
  const EmotionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionDisplayProvider>(
      builder: (context, emotionProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.face, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Emotion Display',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Eye display with full screen button
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Eyes
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Left eye - Cars movie style
                            _buildEye(
                              x: emotionProvider.eyeX,
                              y: emotionProvider.eyeY,
                              openness: emotionProvider.eyeOpenness,
                              pupilSize: emotionProvider.pupilSize,
                              emotion: emotionProvider.currentEmotion,
                            ),
                            
                            // Right eye - Cars movie style
                            _buildEye(
                              x: emotionProvider.eyeX,
                              y: emotionProvider.eyeY,
                              openness: emotionProvider.eyeOpenness,
                              pupilSize: emotionProvider.pupilSize,
                              emotion: emotionProvider.currentEmotion,
                            ),
                          ],
                        ),
                      ),
                      
                      // Full screen button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FullScreenEyesScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Emotion status
                Row(
                  children: [
                    Text(
                      'Current: ${emotionProvider.currentEmotion.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    if (emotionProvider.isTracking)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tracking',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                    if (emotionProvider.steeringAngle != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${emotionProvider.steeringAngle.toInt()}°',
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Emotion controls
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...Emotion.values.map((emotion) => 
                      ActionChip(
                        label: Text(emotion.name),
                        onPressed: () => emotionProvider.setEmotion(emotion),
                        backgroundColor: emotionProvider.currentEmotion == emotion
                          ? Colors.blue.withOpacity(0.3)
                          : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Manual controls
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Eye Position', style: TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: emotionProvider.eyeX,
                                  onChanged: (value) => emotionProvider.setEyePosition(value, emotionProvider.eyeY),
                                  min: -1.0,
                                  max: 1.0,
                                  divisions: 20,
                                ),
                              ),
                              Text('${emotionProvider.eyeX.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: emotionProvider.eyeY,
                                  onChanged: (value) => emotionProvider.setEyePosition(emotionProvider.eyeX, value),
                                  min: -1.0,
                                  max: 1.0,
                                  divisions: 20,
                                ),
                              ),
                              Text('${emotionProvider.eyeY.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Steering simulation
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Steering Angle', style: TextStyle(fontSize: 12)),
                          Slider(
                            value: emotionProvider.steeringAngle,
                            onChanged: emotionProvider.setSteeringAngle,
                            min: -45.0,
                            max: 45.0,
                            divisions: 18,
                          ),
                          Text(
                            '${emotionProvider.steeringAngle.toInt()}°',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Test buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          emotionProvider.startTrackingPerson('test_person');
                          Future.delayed(const Duration(seconds: 3), () {
                            emotionProvider.stopTracking();
                          });
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Test Tracking'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => emotionProvider.setEmotion(Emotion.happy),
                        icon: const Icon(Icons.sentiment_very_satisfied),
                        label: const Text('Happy Test'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEye({
    required double x,
    required double y,
    required double openness,
    required double pupilSize,
    required Emotion emotion,
  }) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Eye white
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          
          // Iris
          Positioned(
            left: 40 + (x * 20) - 12,
            top: 40 + (y * 20) - 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getEmotionColor(emotion),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Pupil
          Positioned(
            left: 40 + (x * 20) - (8 * pupilSize),
            top: 40 + (y * 20) - (8 * pupilSize),
            child: Container(
              width: 16 * pupilSize,
              height: 16 * pupilSize,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Eye lid overlay for blinking/closing
          if (openness < 1.0)
            Positioned.fill(
              child: ClipRect(
                clipper: _EyeLidClipper(openness: openness),
                child: Container(
                  color: Colors.black87,
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

class _EyeLidClipper extends CustomClipper<Rect> {
  final double openness;
  
  const _EyeLidClipper({required this.openness});
  
  @override
  Rect getClip(Size size) {
    final lidHeight = size.height * (1.0 - openness) / 2;
    return Rect.fromLTWH(
      0, 
      0, 
      size.width, 
      size.height * openness
    );
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}