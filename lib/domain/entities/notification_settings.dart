import 'package:irrigation_app/domain/entities/notification.dart';

class NotificationSettings {
  final bool pushNotificationsEnabled;
  final bool inAppNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final SensorThresholds sensorThresholds;
  final SystemAlertSettings systemAlerts;
  final List<NotificationCategory> enabledCategories;
  final TimeRange quietHours;

  NotificationSettings({
    this.pushNotificationsEnabled = true,
    this.inAppNotificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    required this.sensorThresholds,
    required this.systemAlerts,
    this.enabledCategories = const [
      NotificationCategory.sensorAlert,
      NotificationCategory.systemAlert,
      NotificationCategory.irrigationAlert,
      NotificationCategory.connectionAlert,
    ],
    required this.quietHours,
  });
}

class SensorThresholds {
  final double minAirTemperature;
  final double maxAirTemperature;
  final double minAirHumidity;
  final double maxAirHumidity;
  final double minSoilHumidity;
  final double maxSoilHumidity;
  final double minSoilTemperature;
  final double maxSoilTemperature;
  final double maxWindSpeed;
  final double maxRainfall;
  final double minPressure;
  final double maxPressure;

  SensorThresholds({
    this.minAirTemperature = 5.0,
    this.maxAirTemperature = 40.0,
    this.minAirHumidity = 20.0,
    this.maxAirHumidity = 90.0,
    this.minSoilHumidity = 30.0,
    this.maxSoilHumidity = 80.0,
    this.minSoilTemperature = 5.0,
    this.maxSoilTemperature = 35.0,
    this.maxWindSpeed = 50.0,
    this.maxRainfall = 100.0,
    this.minPressure = 95.0,
    this.maxPressure = 105.0,
  });
}

class SystemAlertSettings {
  final bool sensorOfflineAlert;
  final bool connectionLostAlert;
  final bool lowBatteryAlert;
  final bool maintenanceReminders;
  final int sensorOfflineThresholdMinutes;
  final int connectionLostThresholdMinutes;

  SystemAlertSettings({
    this.sensorOfflineAlert = true,
    this.connectionLostAlert = true,
    this.lowBatteryAlert = true,
    this.maintenanceReminders = true,
    this.sensorOfflineThresholdMinutes = 30,
    this.connectionLostThresholdMinutes = 5,
  });
}

class TimeRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  TimeRange({
    this.startHour = 22,
    this.startMinute = 0,
    this.endHour = 7,
    this.endMinute = 0,
  });

  bool isInQuietHours(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final currentMinutes = hour * 60 + minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}
