import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:irrigation_app/domain/entities/notification_settings.dart';
import 'package:irrigation_app/domain/entities/notification.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // General Settings
  bool _pushNotificationsEnabled = true;
  bool _inAppNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  
  // Sensor Thresholds
  double _minAirTemperature = 5.0;
  double _maxAirTemperature = 40.0;
  double _minAirHumidity = 20.0;
  double _maxAirHumidity = 90.0;
  double _minSoilHumidity = 30.0;
  double _maxSoilHumidity = 80.0;
  double _minSoilTemperature = 5.0;
  double _maxSoilTemperature = 35.0;
  double _maxWindSpeed = 50.0;
  double _maxRainfall = 100.0;
  double _minPressure = 95.0;
  double _maxPressure = 105.0;
  
  // System Alerts
  bool _sensorOfflineAlert = true;
  bool _connectionLostAlert = true;
  bool _lowBatteryAlert = true;
  bool _maintenanceReminders = true;
  int _sensorOfflineThresholdMinutes = 30;
  int _connectionLostThresholdMinutes = 5;
  
  // Categories
  final Map<NotificationCategory, bool> _enabledCategories = {
    NotificationCategory.sensorAlert: true,
    NotificationCategory.systemAlert: true,
    NotificationCategory.irrigationAlert: true,
    NotificationCategory.connectionAlert: true,
    NotificationCategory.maintenanceAlert: true,
  };
  
  // Quiet Hours
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _quietHoursEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    final bloc = context.read<NotificationBloc>();
    if (bloc.state is NotificationLoaded) {
      final state = bloc.state as NotificationLoaded;
      final settings = state.settings;
      
      if (settings != null) {
        setState(() {
          _pushNotificationsEnabled = settings.pushNotificationsEnabled;
          _inAppNotificationsEnabled = settings.inAppNotificationsEnabled;
          _emailNotificationsEnabled = settings.emailNotificationsEnabled;
          
          _minAirTemperature = settings.sensorThresholds.minAirTemperature;
          _maxAirTemperature = settings.sensorThresholds.maxAirTemperature;
          _minAirHumidity = settings.sensorThresholds.minAirHumidity;
          _maxAirHumidity = settings.sensorThresholds.maxAirHumidity;
          _minSoilHumidity = settings.sensorThresholds.minSoilHumidity;
          _maxSoilHumidity = settings.sensorThresholds.maxSoilHumidity;
          _minSoilTemperature = settings.sensorThresholds.minSoilTemperature;
          _maxSoilTemperature = settings.sensorThresholds.maxSoilTemperature;
          _maxWindSpeed = settings.sensorThresholds.maxWindSpeed;
          _maxRainfall = settings.sensorThresholds.maxRainfall;
          _minPressure = settings.sensorThresholds.minPressure;
          _maxPressure = settings.sensorThresholds.maxPressure;
          
          _sensorOfflineAlert = settings.systemAlerts.sensorOfflineAlert;
          _connectionLostAlert = settings.systemAlerts.connectionLostAlert;
          _lowBatteryAlert = settings.systemAlerts.lowBatteryAlert;
          _maintenanceReminders = settings.systemAlerts.maintenanceReminders;
          _sensorOfflineThresholdMinutes = settings.systemAlerts.sensorOfflineThresholdMinutes;
          _connectionLostThresholdMinutes = settings.systemAlerts.connectionLostThresholdMinutes;
          
          for (final category in settings.enabledCategories) {
            _enabledCategories[category] = true;
          }
          
          _quietHoursStart = TimeOfDay(
            hour: settings.quietHours.startHour,
            minute: settings.quietHours.startMinute,
          );
          _quietHoursEnd = TimeOfDay(
            hour: settings.quietHours.endHour,
            minute: settings.quietHours.endMinute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Thresholds'),
            Tab(text: 'System'),
            Tab(text: 'Schedule'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildThresholdsTab(),
          _buildSystemTab(),
          _buildScheduleTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notification Types'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications even when app is closed',
            value: _pushNotificationsEnabled,
            onChanged: (value) => setState(() => _pushNotificationsEnabled = value),
            icon: Icons.notifications_active,
          ),
          _buildSwitchTile(
            title: 'In-App Notifications',
            subtitle: 'Show notifications while using the app',
            value: _inAppNotificationsEnabled,
            onChanged: (value) => setState(() => _inAppNotificationsEnabled = value),
            icon: Icons.notifications,
          ),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive critical alerts via email',
            value: _emailNotificationsEnabled,
            onChanged: (value) => setState(() => _emailNotificationsEnabled = value),
            icon: Icons.email,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Notification Categories'),
          ..._enabledCategories.entries.map((entry) => _buildCategoryTile(entry.key, entry.value)),
          const SizedBox(height: 24),
          _buildTestNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildThresholdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Temperature Thresholds'),
          _buildRangeSlider(
            title: 'Air Temperature',
            unit: '°C',
            minValue: _minAirTemperature,
            maxValue: _maxAirTemperature,
            min: -10.0,
            max: 50.0,
            onChanged: (values) => setState(() {
              _minAirTemperature = values.start;
              _maxAirTemperature = values.end;
            }),
            icon: Icons.thermostat,
          ),
          _buildRangeSlider(
            title: 'Soil Temperature',
            unit: '°C',
            minValue: _minSoilTemperature,
            maxValue: _maxSoilTemperature,
            min: -5.0,
            max: 45.0,
            onChanged: (values) => setState(() {
              _minSoilTemperature = values.start;
              _maxSoilTemperature = values.end;
            }),
            icon: Icons.grass,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Humidity Thresholds'),
          _buildRangeSlider(
            title: 'Air Humidity',
            unit: '%',
            minValue: _minAirHumidity,
            maxValue: _maxAirHumidity,
            min: 0.0,
            max: 100.0,
            onChanged: (values) => setState(() {
              _minAirHumidity = values.start;
              _maxAirHumidity = values.end;
            }),
            icon: Icons.water_drop,
          ),
          _buildRangeSlider(
            title: 'Soil Humidity',
            unit: '%',
            minValue: _minSoilHumidity,
            maxValue: _maxSoilHumidity,
            min: 0.0,
            max: 100.0,
            onChanged: (values) => setState(() {
              _minSoilHumidity = values.start;
              _maxSoilHumidity = values.end;
            }),
            icon: Icons.terrain,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Environmental Thresholds'),
          _buildSingleSlider(
            title: 'Max Wind Speed',
            unit: 'km/h',
            value: _maxWindSpeed,
            min: 0.0,
            max: 100.0,
            onChanged: (value) => setState(() => _maxWindSpeed = value),
            icon: Icons.air,
          ),
          _buildSingleSlider(
            title: 'Max Rainfall',
            unit: 'mm',
            value: _maxRainfall,
            min: 0.0,
            max: 200.0,
            onChanged: (value) => setState(() => _maxRainfall = value),
            icon: Icons.water,
          ),
          _buildRangeSlider(
            title: 'Atmospheric Pressure',
            unit: 'kPa',
            minValue: _minPressure,
            maxValue: _maxPressure,
            min: 90.0,
            max: 110.0,
            onChanged: (values) => setState(() {
              _minPressure = values.start;
              _maxPressure = values.end;
            }),
            icon: Icons.compress,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('System Health Alerts'),
          _buildSwitchTile(
            title: 'Sensor Offline Alert',
            subtitle: 'Alert when sensors stop responding',
            value: _sensorOfflineAlert,
            onChanged: (value) => setState(() => _sensorOfflineAlert = value),
            icon: Icons.sensors_off,
          ),
          if (_sensorOfflineAlert)
            _buildThresholdSelector(
              title: 'Sensor Offline Threshold',
              value: _sensorOfflineThresholdMinutes,
              unit: 'minutes',
              options: [5, 10, 15, 30, 60],
              onChanged: (value) => setState(() => _sensorOfflineThresholdMinutes = value),
            ),
          _buildSwitchTile(
            title: 'Connection Lost Alert',
            subtitle: 'Alert when connection to server is lost',
            value: _connectionLostAlert,
            onChanged: (value) => setState(() => _connectionLostAlert = value),
            icon: Icons.wifi_off,
          ),
          if (_connectionLostAlert)
            _buildThresholdSelector(
              title: 'Connection Lost Threshold',
              value: _connectionLostThresholdMinutes,
              unit: 'minutes',
              options: [1, 2, 5, 10, 15],
              onChanged: (value) => setState(() => _connectionLostThresholdMinutes = value),
            ),
          _buildSwitchTile(
            title: 'Low Battery Alert',
            subtitle: 'Alert when sensor battery is low',
            value: _lowBatteryAlert,
            onChanged: (value) => setState(() => _lowBatteryAlert = value),
            icon: Icons.battery_alert,
          ),
          _buildSwitchTile(
            title: 'Maintenance Reminders',
            subtitle: 'Periodic maintenance notifications',
            value: _maintenanceReminders,
            onChanged: (value) => setState(() => _maintenanceReminders = value),
            icon: Icons.build,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Alert Behavior'),
          _buildInfoCard(
            'Alert Cooldown',
            'Duplicate alerts are suppressed for 15 minutes to prevent spam',
            Icons.timer,
          ),
          _buildInfoCard(
            'Critical Alerts',
            'Critical alerts bypass quiet hours and cooldown periods',
            Icons.priority_high,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Quiet Hours'),
          _buildSwitchTile(
            title: 'Enable Quiet Hours',
            subtitle: 'Suppress non-critical notifications during specified hours',
            value: _quietHoursEnabled,
            onChanged: (value) => setState(() => _quietHoursEnabled = value),
            icon: Icons.bedtime,
          ),
          if (_quietHoursEnabled) ...[
            const SizedBox(height: 16),
            _buildTimeSelector(
              title: 'Start Time',
              time: _quietHoursStart,
              onChanged: (time) => setState(() => _quietHoursStart = time),
            ),
            _buildTimeSelector(
              title: 'End Time',
              time: _quietHoursEnd,
              onChanged: (time) => setState(() => _quietHoursEnd = time),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Quiet Hours Info',
              'During quiet hours, only critical alerts will be shown. System alerts and sensor failures will still notify you.',
              Icons.info,
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader('Notification Preview'),
          _buildNotificationPreview(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Colors.green),
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildCategoryTile(NotificationCategory category, bool enabled) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: SwitchListTile(
        title: Text(_getCategoryDisplayName(category)),
        subtitle: Text(_getCategoryDescription(category)),
        value: enabled,
        onChanged: (value) => setState(() => _enabledCategories[category] = value),
        secondary: Icon(_getCategoryIcon(category), color: Colors.green),
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildRangeSlider({
    required String title,
    required String unit,
    required double minValue,
    required double maxValue,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Range: ${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)} $unit',
              style: TextStyle(color: Colors.grey[600]),
            ),
            RangeSlider(
              values: RangeValues(minValue, maxValue),
              min: min,
              max: max,
              divisions: ((max - min) * 2).toInt(),
              labels: RangeLabels(
                '${minValue.toStringAsFixed(1)}$unit',
                '${maxValue.toStringAsFixed(1)}$unit',
              ),
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSlider({
    required String title,
    required String unit,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum: ${value.toStringAsFixed(1)} $unit',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * 2).toInt(),
              label: '${value.toStringAsFixed(1)}$unit',
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSelector({
    required String title,
    required int value,
    required String unit,
    required List<int> options,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: options.map((option) {
                final isSelected = option == value;
                return ChoiceChip(
                  label: Text('$option $unit'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(option);
                  },
                  selectedColor: Colors.green.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.green : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(time.format(context)),
        trailing: const Icon(Icons.access_time),
        onTap: () async {
          final selectedTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (selectedTime != null) {
            onChanged(selectedTime);
          }
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendTestNotification,
        icon: const Icon(Icons.send),
        label: const Text('Send Test Notification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNotificationPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'High Soil Temperature',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Soil temperature is ${_maxSoilTemperature.toStringAsFixed(1)}°C (above threshold)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.sensorAlert:
        return 'Sensor Alerts';
      case NotificationCategory.systemAlert:
        return 'System Alerts';
      case NotificationCategory.irrigationAlert:
        return 'Irrigation Alerts';
      case NotificationCategory.connectionAlert:
        return 'Connection Alerts';
      case NotificationCategory.maintenanceAlert:
        return 'Maintenance Alerts';
    }
  }

  String _getCategoryDescription(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.sensorAlert:
        return 'Temperature, humidity, and environmental alerts';
      case NotificationCategory.systemAlert:
        return 'System health and sensor status alerts';
      case NotificationCategory.irrigationAlert:
        return 'Irrigation start, stop, and failure notifications';
      case NotificationCategory.connectionAlert:
        return 'Network and connectivity issues';
      case NotificationCategory.maintenanceAlert:
        return 'Scheduled maintenance and service reminders';
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.sensorAlert:
        return Icons.sensors;
      case NotificationCategory.systemAlert:
        return Icons.warning;
      case NotificationCategory.irrigationAlert:
        return Icons.water_drop;
      case NotificationCategory.connectionAlert:
        return Icons.wifi_off;
      case NotificationCategory.maintenanceAlert:
        return Icons.build;
    }
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // TODO: Implement actual test notification
    // This would trigger a test notification through the notification service
  }

  void _saveSettings() {
    final settings = NotificationSettings(
      pushNotificationsEnabled: _pushNotificationsEnabled,
      inAppNotificationsEnabled: _inAppNotificationsEnabled,
      emailNotificationsEnabled: _emailNotificationsEnabled,
      sensorThresholds: SensorThresholds(
        minAirTemperature: _minAirTemperature,
        maxAirTemperature: _maxAirTemperature,
        minAirHumidity: _minAirHumidity,
        maxAirHumidity: _maxAirHumidity,
        minSoilHumidity: _minSoilHumidity,
        maxSoilHumidity: _maxSoilHumidity,
        minSoilTemperature: _minSoilTemperature,
        maxSoilTemperature: _maxSoilTemperature,
        maxWindSpeed: _maxWindSpeed,
        maxRainfall: _maxRainfall,
        minPressure: _minPressure,
        maxPressure: _maxPressure,
      ),
      systemAlerts: SystemAlertSettings(
        sensorOfflineAlert: _sensorOfflineAlert,
        connectionLostAlert: _connectionLostAlert,
        lowBatteryAlert: _lowBatteryAlert,
        maintenanceReminders: _maintenanceReminders,
        sensorOfflineThresholdMinutes: _sensorOfflineThresholdMinutes,
        connectionLostThresholdMinutes: _connectionLostThresholdMinutes,
      ),
      enabledCategories: _enabledCategories.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      quietHours: TimeRange(
        startHour: _quietHoursStart.hour,
        startMinute: _quietHoursStart.minute,
        endHour: _quietHoursEnd.hour,
        endMinute: _quietHoursEnd.minute,
      ),
    );

    context.read<NotificationBloc>().add(NotificationUpdateSettings(settings));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.of(context).pop();
  }
}
