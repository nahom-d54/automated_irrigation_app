import 'dart:math';
import 'package:irrigation_app/data/models/sensor_data_model.dart';

class SensorDataLocalSource {
  final Random _random = Random();

  // Generate dummy data for 3 days with readings every 10 minutes
  Future<List<SensorDataModel>> getSensorData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    final List<SensorDataModel> data = [];
    int idCounter = 1;
    
    // Generate data for the past 3 days
    for (int day = 2; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      
      // Generate data points for each day (every 10 minutes)
      for (int hour = 0; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 10) {
          final timestamp = DateTime(
            date.year, 
            date.month, 
            date.day, 
            hour, 
            minute,
          );
          
          // Create some variation in the data
          final hourFactor = hour / 24.0; // 0.0 to 1.0 throughout the day
          final dayProgress = (hour * 60 + minute) / (24 * 60); // 0.0 to 1.0 throughout the day
          
          // Temperature varies throughout the day (cooler at night, warmer during day)
          final airTemperatureC = 20.0 + 10.0 * sin((dayProgress - 0.5) * pi) + _random.nextDouble() * 2 - 1;
          final temperature = airTemperatureC + _random.nextDouble() * 3 - 1.5; // Soil temp similar but with variation
          
          // Humidity is inverse to temperature
          final airHumidity = 40.0 + 30.0 * (1 - sin((dayProgress - 0.5) * pi)) + _random.nextDouble() * 10 - 5;
          
          // Soil humidity decreases throughout the day unless it rains
          final soilHumidity = 60.0 - 20.0 * sin(dayProgress * pi) + 
              (day == 1 && hour > 14 && hour < 16 ? 20.0 : 0.0) + _random.nextDouble() * 5; // Rain on day 1
          
          // Soil moisture related to soil humidity
          final soilMoisture = soilHumidity * 0.8 + _random.nextDouble() * 10;
          
          // Pressure varies slightly
          final pressureKPa = 101.0 + _random.nextDouble() * 2 - 1;
          
          // Wind speed varies throughout the day
          final windSpeedKmh = 5.0 + 15.0 * sin(dayProgress * 2 * pi) + _random.nextDouble() * 5;
          
          // Rainfall (mostly 0, occasional rain)
          final rainfall = (day == 1 && hour > 14 && hour < 16) ? 
              _random.nextDouble() * 10 + 2 : 
              (_random.nextDouble() < 0.05 ? _random.nextDouble() * 2 : 0.0);
          
          // Number of working sensors (usually all working)
          final numberOfWorkingSensors = _random.nextDouble() < 0.95 ? 10.0 : _random.nextInt(8) + 2.0;
          
          // Prediction (0 or 1, mostly 1 for good conditions)
          final prediction = (airTemperatureC > 15 && airTemperatureC < 35 && 
                            soilHumidity > 30 && rainfall < 50) ? 1 : 0;
          
          data.add(SensorDataModel(
            id: idCounter++,
            timestamp: timestamp,
            receivedAt: timestamp.add(Duration(seconds: _random.nextInt(10))),
            createdAt: timestamp.add(Duration(seconds: _random.nextInt(30))),
            updatedAt: _random.nextDouble() < 0.1 ? timestamp.add(Duration(minutes: _random.nextInt(60))) : null,
            airHumidity: airHumidity.clamp(0, 100),
            pressureKPa: pressureKPa,
            soilMoisture: soilMoisture.clamp(0, 100),
            time: timestamp.millisecondsSinceEpoch / 1000.0, // Unix timestamp
            numberOfWorkingSensors: numberOfWorkingSensors,
            rainfall: rainfall,
            soilHumidity: soilHumidity.clamp(0, 100),
            airTemperatureC: airTemperatureC,
            temperature: temperature,
            windSpeedKmh: windSpeedKmh.clamp(0, 50),
            prediction: prediction,
          ));
        }
      }
    }
    
    return data;
  }
}
