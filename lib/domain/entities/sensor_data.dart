class SensorData {
  final int id;
  final DateTime timestamp;
  final DateTime? receivedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double airHumidity;
  final double pressureKPa;
  final double soilMoisture;
  final double time;
  final double numberOfWorkingSensors;
  final double rainfall;
  final double soilHumidity;
  final double airTemperatureC;
  final double temperature;
  final double windSpeedKmh;
  final int prediction;

  SensorData({
    required this.id,
    required this.timestamp,
    this.receivedAt,
    required this.createdAt,
    this.updatedAt,
    required this.airHumidity,
    required this.pressureKPa,
    required this.soilMoisture,
    required this.time,
    required this.numberOfWorkingSensors,
    required this.rainfall,
    required this.soilHumidity,
    required this.airTemperatureC,
    required this.temperature,
    required this.windSpeedKmh,
    required this.prediction,
  });

  // Helper getters for backward compatibility and easier access
  bool get sensorWorking => numberOfWorkingSensors > 0;
  double get airTemperature => airTemperatureC;
  double get soilTemperature => temperature;
}
