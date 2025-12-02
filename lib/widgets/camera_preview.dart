import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart' as camera_pkg;
import '../providers/camera_provider.dart';

class CameraPreview extends StatelessWidget {
  const CameraPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        return Column(
          children: [
            // Camera Status
            Row(
              children: [
                Icon(
                  cameraProvider.isInitialized 
                    ? Icons.camera_alt 
                    : Icons.camera_alt_outlined,
                  color: cameraProvider.isInitialized ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Camera: ${cameraProvider.isInitialized ? 'Initialized' : 'Not Initialized'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (cameraProvider.hasFrontCamera && cameraProvider.hasBackCamera)
                  IconButton(
                    onPressed: cameraProvider.switchCamera,
                    icon: const Icon(Icons.flip_camera_android),
                    tooltip: 'Switch Camera',
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Camera Preview
            if (cameraProvider.isInitialized && cameraProvider.currentCameraController != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: cameraProvider.currentCameraController!.value.aspectRatio,
                    child: camera_pkg.CameraPreview(cameraProvider.currentCameraController!),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Camera preview not available', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Camera Controls
            if (cameraProvider.isInitialized)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cameraProvider.isCapturing ? null : () async {
                            await cameraProvider.captureImage();
                            if (cameraProvider.lastImagePath != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Image saved: ${cameraProvider.lastImagePath}')),
                              );
                            }
                          },
                          icon: const Icon(Icons.photo_camera),
                          label: Text(cameraProvider.isCapturing ? 'Capturing...' : 'Capture Photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: cameraProvider.toggleFlash,
                        icon: Icon(
                          _getFlashIcon(cameraProvider.flashMode),
                        ),
                        tooltip: 'Toggle Flash (${cameraProvider.flashMode.name})',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cameraProvider.isRecording 
                            ? () async {
                                await cameraProvider.stopVideoRecording();
                                if (cameraProvider.lastVideoPath != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Video saved: ${cameraProvider.lastVideoPath}')),
                                  );
                                }
                              }
                            : () async {
                                await cameraProvider.startVideoRecording();
                              },
                          icon: Icon(
                            cameraProvider.isRecording ? Icons.stop : Icons.videocam,
                          ),
                          label: Text(
                            cameraProvider.isRecording 
                              ? 'Stop Recording (${_formatDuration(cameraProvider.recordingDuration)})'
                              : 'Start Video',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cameraProvider.isRecording ? Colors.red : null,
                            foregroundColor: cameraProvider.isRecording ? Colors.white : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (cameraProvider.isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(
                        value: null, // Indeterminate progress
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Camera Info
            if (cameraProvider.cameras.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Cameras:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    ...cameraProvider.cameras.map((camera) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Row(
                        children: [
                          Icon(
                            camera.lensDirection == camera_pkg.CameraLensDirection.front 
                              ? Icons.camera_front 
                              : Icons.camera_rear,
                            size: 16,
                            color: camera.lensDirection == cameraProvider.currentLensDirection 
                              ? Colors.blue 
                              : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${camera.name} (${camera.lensDirection.name})',
                              style: TextStyle(
                                fontSize: 11,
                                color: camera.lensDirection == cameraProvider.currentLensDirection 
                                  ? Colors.blue 
                                  : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            
            // Last Media Info
            if (cameraProvider.lastImagePath != null || cameraProvider.lastVideoPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cameraProvider.lastImagePath != null)
                      Text(
                        'Last Photo: ${cameraProvider.lastImagePath}',
                        style: const TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    if (cameraProvider.lastVideoPath != null)
                      Text(
                        'Last Video: ${cameraProvider.lastVideoPath}',
                        style: const TextStyle(fontSize: 10, color: Colors.green),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
  
  IconData _getFlashIcon(camera_pkg.FlashMode mode) {
    switch (mode) {
      case camera_pkg.FlashMode.auto:
        return Icons.flash_auto;
      case camera_pkg.FlashMode.always:
        return Icons.flash_on;
      case camera_pkg.FlashMode.off:
        return Icons.flash_off;
      case camera_pkg.FlashMode.torch:
        return Icons.flashlight_on;
    }
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}