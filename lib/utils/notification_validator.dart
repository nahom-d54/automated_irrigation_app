import 'package:irrigation_app/domain/entities/notification_settings.dart';

class NotificationValidator {
  static ValidationResult validateSensorThresholds(SensorThresholds thresholds) {
    final errors = <String>[];

    // Air Temperature validation
    if (thresholds.minAirTemperature >= thresholds.maxAirTemperature) {
      errors.add('Air temperature: minimum must be less than maximum');
    }
    if (thresholds.minAirTemperature < -20 || thresholds.maxAirTemperature > 60) {
      errors.add('Air temperature: values must be between -20°C and 60°C');
    }

    // Air Humidity validation
    if (thresholds.minAirHumidity >= thresholds.maxAirHumidity) {
      errors.add('Air humidity: minimum must be less than maximum');
    }
    if (thresholds.minAirHumidity < 0 || thresholds.maxAirHumidity > 100) {
      errors.add('Air humidity: values must be between 0% and 100%');
    }

    // Soil Humidity validation
    if (thresholds.minSoilHumidity >= thresholds.maxSoilHumidity) {
      errors.add('Soil humidity: minimum must be less than maximum');
    }
    if (thresholds.minSoilHumidity < 0 || thresholds.maxSoilHumidity > 100) {
      errors.add('Soil humidity: values must be between 0% and 100%');
    }

    // Soil Temperature validation
    if (thresholds.minSoilTemperature >= thresholds.maxSoilTemperature) {
      errors.add('Soil temperature: minimum must be less than maximum');
    }
    if (thresholds.minSoilTemperature < -10 || thresholds.maxSoilTemperature > 50) {
      errors.add('Soil temperature: values must be between -10°C and 50°C');
    }

    // Wind Speed validation
    if (thresholds.maxWindSpeed < 0 || thresholds.maxWindSpeed > 200) {
      errors.add('Wind speed: maximum must be between 0 and 200 km/h');
    }

    // Rainfall validation
    if (thresholds.maxRainfall < 0 || thresholds.maxRainfall > 500) {
      errors.add('Rainfall: maximum must be between 0 and 500 mm');
    }

    // Pressure validation
    if (thresholds.minPressure >= thresholds.maxPressure) {
      errors.add('Pressure: minimum must be less than maximum');
    }
    if (thresholds.minPressure < 80 || thresholds.maxPressure > 120) {
      errors.add('Pressure: values must be between 80 and 120 kPa');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  static ValidationResult validateSystemAlerts(SystemAlertSettings alerts) {
    final errors = <String>[];

    if (alerts.sensorOfflineThresholdMinutes < 1 || alerts.sensorOfflineThresholdMinutes > 1440) {
      errors.add('Sensor offline threshold must be between 1 and 1440 minutes');
    }

    if (alerts.connectionLostThresholdMinutes < 1 || alerts.connectionLostThresholdMinutes > 60) {
      errors.add('Connection lost threshold must be between 1 and 60 minutes');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  static List<String> getRecommendations(SensorThresholds thresholds) {
    final recommendations = <String>[];

    // Soil humidity recommendations
    if (thresholds.minSoilHumidity > 40) {
      recommendations.add('Consider lowering minimum soil humidity to 30-35% for better irrigation efficiency');
    }
    if (thresholds.maxSoilHumidity < 70) {
      recommendations.add('Consider raising maximum soil humidity to 75-80% to prevent overwatering alerts');
    }

    // Temperature recommendations
    if (thresholds.maxAirTemperature < 35) {
      recommendations.add('Consider raising maximum air temperature threshold for hot climate conditions');
    }
    if (thresholds.minAirTemperature > 10) {
      recommendations.add('Consider lowering minimum air temperature for frost protection');
    }

    // Wind speed recommendations
    if (thresholds.maxWindSpeed > 60) {
      recommendations.add('High wind speed threshold may miss important weather warnings');
    }

    return recommendations;
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}
