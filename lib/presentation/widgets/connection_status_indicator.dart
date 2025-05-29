import 'package:flutter/material.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final String? socketId;
  final VoidCallback onReconnectPressed;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.socketId,
    required this.onReconnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String message;
    bool showReconnect = false;

    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        icon = Icons.cloud_done;
        message = 'Connected via Socket.IO';
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        icon = Icons.cloud_sync;
        message = 'Connecting to Socket.IO...';
        break;
      case ConnectionStatus.disconnected:
        color = Colors.grey;
        icon = Icons.cloud_off;
        message = 'Socket.IO Disconnected';
        showReconnect = true;
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        icon = Icons.error_outline;
        message = 'Socket.IO Connection Error';
        showReconnect = true;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (socketId != null && status == ConnectionStatus.connected)
                        Text(
                          'Socket ID: ${socketId!.substring(0, 8)}...',
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showReconnect)
                  TextButton.icon(
                    onPressed: onReconnectPressed,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
