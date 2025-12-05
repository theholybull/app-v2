import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pi_connection_provider.dart';
import '../core/vision/vision_service.dart';

class ViamConnectionWidget extends StatelessWidget {
  const ViamConnectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pi = context.watch<PiConnectionProvider>();
    final vision = context.watch<VisionService>();

    final status = pi.connectionStatus;
    final connected = status.isConnected;
    final address = status.piAddress ?? 'Unknown';
    final ping = status.lastPing >= 0 ? '${status.lastPing} ms' : '—';
    final type = status.connectionType ?? 'Unknown';
    final error = status.error;

    final hasFaces = vision.hasFaces;
    final numFaces = vision.numFaces;

    Color badgeColor;
    String badgeText;

    if (connected) {
      badgeColor = Colors.green;
      badgeText = 'Connected';
    } else if (pi.isScanning) {
      badgeColor = Colors.orange;
      badgeText = 'Scanning...';
    } else {
      badgeColor = Colors.red;
      badgeText = 'Not connected';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.router),
                const SizedBox(width: 8),
                const Text(
                  'Pi Link & Vision',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'Address',
                  value: address,
                  icon: Icons.lan,
                ),
                _InfoChip(
                  label: 'Type',
                  value: type,
                  icon: Icons.wifi,
                ),
                _InfoChip(
                  label: 'Ping',
                  value: ping,
                  icon: Icons.timelapse,
                ),
                _InfoChip(
                  label: 'Vision faces',
                  value: hasFaces ? '$numFaces' : '0',
                  icon: Icons.face_retouching_natural,
                ),
              ],
            ),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pi.isScanning
                      ? null
                      : () async {
                    await pi.scanForPi();
                  },
                  icon: pi.isScanning
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.search),
                  label:
                  Text(pi.isScanning ? 'Scanning…' : 'Scan for Pi on LAN'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: connected
                      ? () async {
                    await pi.disconnect();
                  }
                      : null,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
