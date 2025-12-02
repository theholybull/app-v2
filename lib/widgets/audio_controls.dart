import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return Column(
          children: [
            // Microphone Status
            Row(
              children: [
                Icon(
                  audioProvider.isMicrophoneAvailable 
                    ? Icons.mic 
                    : Icons.mic_off,
                  color: audioProvider.isMicrophoneAvailable 
                    ? Colors.green 
                    : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Microphone: ${audioProvider.isMicrophoneAvailable ? 'Available' : 'Not Available'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Recording Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: audioProvider.isRecording 
                      ? () => audioProvider.stopRecording()
                      : () => audioProvider.startRecording(),
                    icon: Icon(
                      audioProvider.isRecording ? Icons.stop : Icons.mic,
                    ),
                    label: Text(
                      audioProvider.isRecording ? 'Stop Recording' : 'Start Recording',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: audioProvider.isRecording ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            if (audioProvider.isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: null, // Indeterminate progress
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recording... ${_formatDuration(audioProvider.recordingDuration)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Speaker Status
            Row(
              children: [
                Icon(
                  audioProvider.isSpeakerAvailable 
                    ? Icons.volume_up 
                    : Icons.volume_off,
                  color: audioProvider.isSpeakerAvailable 
                    ? Colors.green 
                    : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Speaker: ${audioProvider.isSpeakerAvailable ? 'Available' : 'Not Available'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Playback Controls
            if (audioProvider.currentRecordingPath != null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: audioProvider.isPlaying
                            ? () => audioProvider.pausePlayback()
                            : () => audioProvider.playAudio(audioProvider.currentRecordingPath!),
                          icon: Icon(
                            audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            audioProvider.isPlaying ? 'Pause' : 'Play Recording',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: audioProvider.isPlaying 
                          ? () => audioProvider.stopPlayback()
                          : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                  
                  if (audioProvider.totalDuration.inMilliseconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: [
                          Slider(
                            value: audioProvider.playbackPosition.inMilliseconds.toDouble(),
                            max: audioProvider.totalDuration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              audioProvider.seekTo(Duration(milliseconds: value.round()));
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(audioProvider.playbackPosition),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                _formatDuration(audioProvider.totalDuration),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Test Controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => audioProvider.testSpeakers(),
                    icon: const Icon(Icons.surround_sound),
                    label: const Text('Test Speakers'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showVolumeControl(context, audioProvider),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Volume'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  void _showVolumeControl(BuildContext context, AudioProvider audioProvider) {
    double volume = 1.0; // Default volume
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume Control'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Volume: ${(volume * 100).round()}%'),
                Slider(
                  value: volume,
                  onChanged: (value) {
                    setState(() {
                      volume = value;
                    });
                    audioProvider.setVolume(value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}