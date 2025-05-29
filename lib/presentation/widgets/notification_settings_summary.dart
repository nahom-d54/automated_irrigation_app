import 'package:flutter/material.dart';
import 'package:irrigation_app/domain/entities/notification_settings.dart';
import 'package:irrigation_app/utils/notification_validator.dart';

class NotificationSettingsSummary extends StatelessWidget {
  final NotificationSettings settings;
  final VoidCallback? onEdit;

  const NotificationSettingsSummary({
    super.key,
    required this.settings,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final validation = NotificationValidator.validateSensorThresholds(settings.sensorThresholds);
    final recommendations = NotificationValidator.getRecommendations(settings.sensorThresholds);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Settings Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Settings',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGeneralSettings(),
            const SizedBox(height: 16),
            _buildThresholdSettings(),
            const SizedBox(height: 16),
            _buildSystemSettings(),
            if (!validation.isValid) ...[
              const SizedBox(height: 16),
              _buildValidationErrors(validation.errors),
            ],
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRecommendations(recommendations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip('Push', settings.pushNotificationsEnabled),
            const SizedBox(width: 8),
            _buildStatusChip('In-App', settings.inAppNotificationsEnabled),
            const SizedBox(width: 8),
            _buildStatusChip('Email', settings.emailNotificationsEnabled),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Active Categories: ${settings.enabledCategories.length}/5',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildThresholdSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sensor Thresholds',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            _buildThresholdChip(
              'Air Temp',
              '${settings.sensorThresholds.minAirTemperature.toStringAsFixed(0)}-${settings.sensorThresholds.maxAirTemperature.toStringAsFixed(0)}°C',
            ),
            _buildThresholdChip(
              'Soil Temp',
              '${settings.sensorThresholds.minSoilTemperature.toStringAsFixed(0)}-${settings.sensorThresholds.maxSoilTemperature.toStringAsFixed(0)}°C',
            ),
            _buildThresholdChip(
              'Air Humidity',
              '${settings.sensorThresholds.minAirHumidity.toStringAsFixed(0)}-${settings.sensorThresholds.maxAirHumidity.toStringAsFixed(0)}%',
            ),
            _buildThresholdChip(
              'Soil Humidity',
              '${settings.sensorThresholds.minSoilHumidity.toStringAsFixed(0)}-${settings.sensorThresholds.maxSoilHumidity.toStringAsFixed(0)}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Alerts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip('Sensor Offline', settings.systemAlerts.sensorOfflineAlert),
            const SizedBox(width: 8),
            _buildStatusChip('Connection Lost', settings.systemAlerts.connectionLostAlert),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildStatusChip('Low Battery', settings.systemAlerts.lowBatteryAlert),
            const SizedBox(width: 8),
            _buildStatusChip('Maintenance', settings.systemAlerts.maintenanceReminders),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Quiet Hours: ${_formatTime(settings.quietHours.startHour, settings.quietHours.startMinute)} - ${_formatTime(settings.quietHours.endHour, settings.quietHours.endMinute)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool enabled) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
      backgroundColor: enabled ? Colors.green.shade100 : Colors.grey.shade200,
      side: BorderSide(
        color: enabled ? Colors.green : Colors.grey,
        width: 1,
      ),
    );
  }

  Widget _buildThresholdChip(String label, String value) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
    );
  }

  Widget _buildValidationErrors(List<String> errors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Configuration Issues',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map((error) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $error',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $recommendation',
              style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
