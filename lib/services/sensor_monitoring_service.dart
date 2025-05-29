import 'dart:async';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:irrigation_app/domain/entities/notification.dart';
import 'package:irrigation_app/domain/entities/notification_settings.dart';
import 'package:irrigation_app/services/notification_service.dart';
import 'package:irrigation_app/data/models/notification_model.dart';

class SensorMonitoringService {
  static final SensorMonitoringService _instance = SensorMonitoringService._internal();
  factory SensorMonitoringService() => _instance;
  SensorMonitoringService._internal();

  final NotificationService _notificationService = NotificationService();
  
  SensorData? _lastSensorData;
  DateTime? _lastDataReceived;
  Timer? _connectionCheckTimer;
  final Map<String, DateTime> _lastAlertTimes = {};
  
  // Cooldown period to prevent spam notifications (in minutes)
  static const int alertCooldownMinutes = 15;

  Future<void> initialize() async {
    // await _notificationService.initialize();
    _startConnectionMonitoring();
  }

  void _startConnectionMonitoring() {
    _connectionCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkConnectionStatus();
    });
  }

  void _checkConnectionStatus() {
    if (_lastDataReceived == null) return;

    final now = DateTime.now();
    final timeSinceLastData = now.difference(_lastDataReceived!);
    
    final settings = _notificationService.settings;
    final thresholdMinutes = settings?.systemAlerts.connectionLostThresholdMinutes ?? 5;

    if (timeSinceLastData.inMinutes > thresholdMinutes) {
      _sendConnectionLostAlert(timeSinceLastData);
    }
  }

  Future<void> processSensorData(SensorData sensorData) async {
    _lastSensorData = sensorData;
    _lastDataReceived = DateTime.now();

    final settings = _notificationService.settings;
    if (settings == null) return;

    await _checkSensorThresholds(sensorData, settings.sensorThresholds);
    await _checkSensorStatus(sensorData, settings.systemAlerts);
  }

  Future<void> _checkSensorThresholds(SensorData data, SensorThresholds thresholds) async {
    // Air Temperature
    if (data.airTemperatureC < thresholds.minAirTemperature) {
      await _sendThresholdAlert(
        'Low Air Temperature',
        'Air temperature is ${data.airTemperatureC.toStringAsFixed(1)}°C (below ${thresholds.minAirTemperature}°C)',
        NotificationType.warning,
        'air_temp_low',
      );
    } else if (data.airTemperatureC > thresholds.maxAirTemperature) {
      await _sendThresholdAlert(
        'High Air Temperature',
        'Air temperature is ${data.airTemperatureC.toStringAsFixed(1)}°C (above ${thresholds.maxAirTemperature}°C)',
        NotificationType.critical,
        'air_temp_high',
      );
    }

    // Air Humidity
    if (data.airHumidity < thresholds.minAirHumidity) {
      await _sendThresholdAlert(
        'Low Air Humidity',
        'Air humidity is ${data.airHumidity.toStringAsFixed(1)}% (below ${thresholds.minAirHumidity}%)',
        NotificationType.warning,
        'air_humidity_low',
      );
    } else if (data.airHumidity > thresholds.maxAirHumidity) {
      await _sendThresholdAlert(
        'High Air Humidity',
        'Air humidity is ${data.airHumidity.toStringAsFixed(1)}% (above ${thresholds.maxAirHumidity}%)',
        NotificationType.warning,
        'air_humidity_high',
      );
    }

    // Soil Humidity
    if (data.soilHumidity < thresholds.minSoilHumidity) {
      await _sendThresholdAlert(
        'Low Soil Humidity - Irrigation Needed',
        'Soil humidity is ${data.soilHumidity.toStringAsFixed(1)}% (below ${thresholds.minSoilHumidity}%)',
        NotificationType.critical,
        'soil_humidity_low',
      );
    } else if (data.soilHumidity > thresholds.maxSoilHumidity) {
      await _sendThresholdAlert(
        'High Soil Humidity',
        'Soil humidity is ${data.soilHumidity.toStringAsFixed(1)}% (above ${thresholds.maxSoilHumidity}%)',
        NotificationType.warning,
        'soil_humidity_high',
      );
    }

    // Soil Temperature
    if (data.soilTemperature < thresholds.minSoilTemperature) {
      await _sendThresholdAlert(
        'Low Soil Temperature',
        'Soil temperature is ${data.soilTemperature.toStringAsFixed(1)}°C (below ${thresholds.minSoilTemperature}°C)',
        NotificationType.warning,
        'soil_temp_low',
      );
    } else if (data.soilTemperature > thresholds.maxSoilTemperature) {
      await _sendThresholdAlert(
        'High Soil Temperature',
        'Soil temperature is ${data.soilTemperature.toStringAsFixed(1)}°C (above ${thresholds.maxSoilTemperature}°C)',
        NotificationType.warning,
        'soil_temp_high',
      );
    }

    // Wind Speed
    if (data.windSpeedKmh > thresholds.maxWindSpeed) {
      await _sendThresholdAlert(
        'High Wind Speed Alert',
        'Wind speed is ${data.windSpeedKmh.toStringAsFixed(1)} km/h (above ${thresholds.maxWindSpeed} km/h)',
        NotificationType.warning,
        'wind_speed_high',
      );
    }

    // Rainfall
    if (data.rainfall > thresholds.maxRainfall) {
      await _sendThresholdAlert(
        'Heavy Rainfall Alert',
        'Rainfall is ${data.rainfall.toStringAsFixed(1)} mm (above ${thresholds.maxRainfall} mm)',
        NotificationType.warning,
        'rainfall_high',
      );
    }

    // Pressure
    if (data.pressureKPa < thresholds.minPressure) {
      await _sendThresholdAlert(
        'Low Atmospheric Pressure',
        'Pressure is ${data.pressureKPa.toStringAsFixed(1)} kPa (below ${thresholds.minPressure} kPa)',
        NotificationType.info,
        'pressure_low',
      );
    } else if (data.pressureKPa > thresholds.maxPressure) {
      await _sendThresholdAlert(
        'High Atmospheric Pressure',
        'Pressure is ${data.pressureKPa.toStringAsFixed(1)} kPa (above ${thresholds.maxPressure} kPa)',
        NotificationType.info,
        'pressure_high',
      );
    }
  }

  Future<void> _checkSensorStatus(SensorData data, SystemAlertSettings settings) async {
    // Check sensor working status
    if (!data.sensorWorking && settings.sensorOfflineAlert) {
      await _sendSystemAlert(
        'Sensors Offline',
        'Only ${data.numberOfWorkingSensors.toInt()} sensors are working. Check sensor connections.',
        NotificationType.critical,
        'sensors_offline',
      );
    }

    // Check prediction status
    if (data.prediction == 0) {
      await _sendSystemAlert(
        'System Prediction Alert',
        'Environmental conditions require attention. Check sensor readings.',
        NotificationType.warning,
        'prediction_alert',
      );
    }
  }

  Future<void> _sendThresholdAlert(
    String title,
    String message,
    NotificationType type,
    String alertKey,
  ) async {
    if (!_shouldSendAlert(alertKey)) return;

    final notification = NotificationModel(
      id: '${alertKey}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      category: NotificationCategory.sensorAlert,
      timestamp: DateTime.now(),
      data: {
        'alert_key': alertKey,
        'sensor_data': _lastSensorData?.toJson(),
      },
    );

    await _notificationService.showNotification(notification);
    _lastAlertTimes[alertKey] = DateTime.now();
  }

  Future<void> _sendSystemAlert(
    String title,
    String message,
    NotificationType type,
    String alertKey,
  ) async {
    if (!_shouldSendAlert(alertKey)) return;

    final notification = NotificationModel(
      id: '${alertKey}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      category: NotificationCategory.systemAlert,
      timestamp: DateTime.now(),
      data: {
        'alert_key': alertKey,
        'sensor_data': _lastSensorData?.toJson(),
      },
    );

    await _notificationService.showNotification(notification);
    _lastAlertTimes[alertKey] = DateTime.now();
  }

  Future<void> _sendConnectionLostAlert(Duration timeSinceLastData) async {
    const alertKey = 'connection_lost';
    if (!_shouldSendAlert(alertKey)) return;

    final notification = NotificationModel(
      id: '${alertKey}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Connection Lost',
      message: 'No sensor data received for ${timeSinceLastData.inMinutes} minutes',
      type: NotificationType.critical,
      category: NotificationCategory.connectionAlert,
      timestamp: DateTime.now(),
      data: {
        'alert_key': alertKey,
        'minutes_offline': timeSinceLastData.inMinutes,
      },
    );

    await _notificationService.showNotification(notification);
    _lastAlertTimes[alertKey] = DateTime.now();
  }

  Future<void> sendIrrigationAlert(String zone, int duration, bool success) async {
    final notification = NotificationModel(
      id: 'irrigation_${DateTime.now().millisecondsSinceEpoch}',
      title: success ? 'Irrigation Started' : 'Irrigation Failed',
      message: success 
          ? 'Irrigation started for $zone (${duration}min)'
          : 'Failed to start irrigation for $zone',
      type: success ? NotificationType.success : NotificationType.critical,
      category: NotificationCategory.irrigationAlert,
      timestamp: DateTime.now(),
      data: {
        'zone': zone,
        'duration': duration,
        'success': success,
      },
    );

    await _notificationService.showNotification(notification);
  }

  bool _shouldSendAlert(String alertKey) {
    final lastAlert = _lastAlertTimes[alertKey];
    if (lastAlert == null) return true;

    final now = DateTime.now();
    final timeSinceLastAlert = now.difference(lastAlert);
    
    return timeSinceLastAlert.inMinutes >= alertCooldownMinutes;
  }

  void dispose() {
    _connectionCheckTimer?.cancel();
  }
}

// Extension to add toJson method to SensorData
extension SensorDataJson on SensorData {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'air_temperature': airTemperatureC,
      'air_humidity': airHumidity,
      'soil_humidity': soilHumidity,
      'soil_temperature': soilTemperature,
      'wind_speed': windSpeedKmh,
      'rainfall': rainfall,
      'pressure': pressureKPa,
      'sensors_working': numberOfWorkingSensors,
      'prediction': prediction,
    };
  }
}
