import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/face_detection_provider.dart';
import '../providers/emotion_display_provider.dart';

class FaceDetectionControls extends StatelessWidget {
  const FaceDetectionControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FaceDetectionProvider, EmotionDisplayProvider>(
      builder: (context, faceProvider, emotionProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      faceProvider.isDetecting ? Icons.face : Icons.face_outlined,
                      color: faceProvider.isDetecting ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Face Detection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Switch(
                      value: faceProvider.isDetecting,
                      onChanged: (value) {
                        if (value) {
                          faceProvider.startDetection();
                        } else {
                          faceProvider.stopDetection();
                        }
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Detection status
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: faceProvider.isDetecting ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      faceProvider.isDetecting 
                        ? 'Detecting faces...' 
                        : 'Detection stopped',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    if (faceProvider.detectedFaces.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${faceProvider.detectedFaces.length} faces',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    if (faceProvider.trackedFaceId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tracking',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Face list
                if (faceProvider.detectedFaces.isNotEmpty)
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: faceProvider.detectedFaces.length,
                      itemBuilder: (context, index) {
                        final face = faceProvider.detectedFaces[index];
                        final isTracked = face.id == faceProvider.trackedFaceId;
                        
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isTracked 
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: isTracked 
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  face.id,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (face.smilingProbability != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.sentiment_satisfied_alt, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${(face.smilingProbability! * 100).toInt()}%',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                if (face.leftEyeOpenProbability != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${(face.leftEyeOpenProbability! * 100).toInt()}%',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                const Spacer(),
                                if (!isTracked)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        faceProvider.trackFace(face.id);
                                        emotionProvider.startTrackingPerson(face.id);
                                      },
                                      child: const Text('Track'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                if (faceProvider.detectedFaces.isNotEmpty)
                  const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: faceProvider.trackedFaceId != null 
                          ? () {
                              faceProvider.untrackFace();
                              emotionProvider.stopTracking();
                            }
                          : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Tracking'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: faceProvider.isInitialized 
                          ? () {
                              faceProvider.stopDetection();
                              faceProvider.initialize();
                            }
                          : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart'),
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
}