import 'package:flutter/material.dart';

class CameraPreviewCard extends StatelessWidget {
  const CameraPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder for now — we can wire your live camera / sensor streams
    // into this card later without breaking the layout.
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.sensors),
                SizedBox(width: 8),
                Text(
                  'Sensors & Camera',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Sensor and camera views will show up here.\n'
                  'For now this is just a stub to keep the app compiling cleanly.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
