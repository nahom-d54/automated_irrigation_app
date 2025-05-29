import 'package:irrigation_app/domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  SensorDataModel({
    required super.id,
    required super.timestamp,
    super.receivedAt,
    required super.createdAt,
    super.updatedAt,
    required super.airHumidity,
    required super.pressureKPa,
    required super.soilMoisture,
    required super.time,
    required super.numberOfWorkingSensors,
    required super.rainfall,
    required super.soilHumidity,
    required super.airTemperatureC,
    required super.temperature,
    required super.windSpeedKmh,
    required super.prediction,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      id: json['id']?.toInt() ?? 0,
      timestamp: _parseDateTime(json['timestamp']),
      receivedAt: json['received_at'] != null ? _parseDateTime(json['received_at']) : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: json['updated_at'] != null ? _parseDateTime(json['updated_at']) : null,
      airHumidity: (json['Air_humidity_'] ?? 0).toDouble(),
      pressureKPa: (json['Pressure_KPa'] ?? 0).toDouble(),
      soilMoisture: (json['Soil_Moisture'] ?? 0).toDouble(),
      time: (json['Time'] ?? 0).toDouble(),
      numberOfWorkingSensors: (json['number_of_working_sensors'] ?? 0).toDouble(),
      rainfall: (json['rainfall'] ?? 0).toDouble(),
      soilHumidity: (json['Soil_Humidity'] ?? 0).toDouble(),
      airTemperatureC: (json['Air_temperature_C'] ?? 0).toDouble(),
      temperature: (json['Temperature'] ?? 0).toDouble(),
      windSpeedKmh: (json['Wind_speed_Kmh'] ?? 0).toDouble(),
      prediction: (json['prediction'] ?? 0).toInt(),
    );
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else if (dateTime is num) {
      // Handle Unix timestamp
      return DateTime.fromMillisecondsSinceEpoch((dateTime * 1000).toInt());
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'received_at': receivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'Air_humidity_': airHumidity,
      'Pressure_KPa': pressureKPa,
      'Soil_Moisture': soilMoisture,
      'Time': time,
      'number_of_working_sensors': numberOfWorkingSensors,
      'rainfall': rainfall,
      'Soil_Humidity': soilHumidity,
      'Air_temperature_C': airTemperatureC,
      'Temperature': temperature,
      'Wind_speed_Kmh': windSpeedKmh,
      'prediction': prediction,
    };
  }
}
