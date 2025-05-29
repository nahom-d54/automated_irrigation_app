import 'package:flutter/material.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final SensorData latestData;

  const SummaryCard({super.key, required this.latestData});

  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Readings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM d, h:mm a').format(latestData.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'ID: ${latestData.id}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // First row - Temperature and Air Humidity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  Icons.thermostat,
                  'Air Temp',
                  '${latestData.airTemperatureC.toStringAsFixed(1)}°C',
                  Colors.orange,
                ),
                _buildSummaryItem(
                  context,
                  Icons.water_drop_outlined,
                  'Air Humidity',
                  '${latestData.airHumidity.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Second row - Soil data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  Icons.grass,
                  'Soil Humidity',
                  '${latestData.soilHumidity.toStringAsFixed(1)}%',
                  Colors.green,
                ),
                _buildSummaryItem(
                  context,
                  Icons.terrain,
                  'Soil Moisture',
                  '${latestData.soilMoisture.toStringAsFixed(1)}%',
                  Colors.brown,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Third row - Environmental data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  Icons.air,
                  'Wind Speed',
                  '${latestData.windSpeedKmh.toStringAsFixed(1)} km/h',
                  Colors.cyan,
                ),
                _buildSummaryItem(
                  context,
                  Icons.compress,
                  'Pressure',
                  '${latestData.pressureKPa.toStringAsFixed(1)} kPa',
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Fourth row - Rainfall and Prediction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  Icons.water,
                  'Rainfall',
                  '${latestData.rainfall.toStringAsFixed(1)} mm',
                  Colors.indigo,
                ),
                _buildSummaryItem(
                  context,
                  latestData.prediction == 1 ? Icons.check_circle : Icons.warning,
                  'Prediction',
                  latestData.prediction == 1 ? 'Good' : 'Alert',
                  latestData.prediction == 1 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sensors status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: latestData.sensorWorking ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: latestData.sensorWorking ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sensors,
                    color: latestData.sensorWorking ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${latestData.numberOfWorkingSensors.toInt()} sensors working',
                    style: TextStyle(
                      color: latestData.sensorWorking ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
