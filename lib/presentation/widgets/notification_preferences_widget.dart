import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:irrigation_app/presentation/pages/notification_settings_page.dart';
import 'package:irrigation_app/domain/entities/notification_settings.dart';

class NotificationPreferencesWidget extends StatelessWidget {
  const NotificationPreferencesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoaded) {
          return _buildPreferencesCard(context, state.settings);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPreferencesCard(BuildContext context, NotificationSettings? settings) {
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
                const Icon(Icons.settings, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Notification Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // TextButton(
                //   onPressed: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (context) => const NotificationSettingsPage(),
                //       ),
                //     );
                //   },
                //   child: const Text('Customize'),
                // ),
              ],
            ),
            const SizedBox(height: 16),
            if (settings != null) ...[
              _buildQuickSetting(
                'Push Notifications',
                settings.pushNotificationsEnabled,
                Icons.notifications_active,
                (value) => _updatePushNotifications(context, value),
              ),
              _buildQuickSetting(
                'In-App Notifications',
                settings.inAppNotificationsEnabled,
                Icons.notifications,
                (value) => _updateInAppNotifications(context, value),
              ),
              const SizedBox(height: 12),
              _buildThresholdSummary(settings.sensorThresholds),
            ] else ...[
              const Text('Loading preferences...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSetting(
    String title,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSummary(SensorThresholds thresholds) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Thresholds',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildThresholdItem(
                  'Air Temp',
                  '${thresholds.minAirTemperature.toStringAsFixed(0)}-${thresholds.maxAirTemperature.toStringAsFixed(0)}°C',
                ),
              ),
              Expanded(
                child: _buildThresholdItem(
                  'Soil Humidity',
                  '${thresholds.minSoilHumidity.toStringAsFixed(0)}-${thresholds.maxSoilHumidity.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _updatePushNotifications(BuildContext context, bool value) {
    // TODO: Update push notification setting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Push notifications enabled' : 'Push notifications disabled'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateInAppNotifications(BuildContext context, bool value) {
    // TODO: Update in-app notification setting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'In-app notifications enabled' : 'In-app notifications disabled'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
