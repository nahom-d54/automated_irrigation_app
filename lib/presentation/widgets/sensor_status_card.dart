import 'package:flutter/material.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';

class SensorStatusCard extends StatelessWidget {
  final SensorData sensorData;

  const SensorStatusCard({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    final isWorking = sensorData.sensorWorking;
    final workingSensors = sensorData.numberOfWorkingSensors.toInt();
    final prediction = sensorData.prediction;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isWorking ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sensor Status Row
            Row(
              children: [
                Icon(
                  isWorking ? Icons.check_circle : Icons.error,
                  color: isWorking ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$workingSensors Sensors Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isWorking ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      Text(
                        isWorking ? 'System Operating Normally' : 'Check Sensor Connections',
                        style: TextStyle(
                          color: isWorking ? Colors.green.shade600 : Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Prediction Status Row
            Row(
              children: [
                Icon(
                  prediction == 1 ? Icons.wb_sunny : Icons.warning_amber,
                  color: prediction == 1 ? Colors.orange : Colors.amber,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction == 1 ? 'Optimal Conditions' : 'Attention Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: prediction == 1 ? Colors.orange.shade800 : Colors.amber.shade800,
                        ),
                      ),
                      Text(
                        prediction == 1 
                            ? 'Irrigation conditions are favorable'
                            : 'Monitor environmental conditions',
                        style: TextStyle(
                          color: prediction == 1 ? Colors.orange.shade600 : Colors.amber.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
