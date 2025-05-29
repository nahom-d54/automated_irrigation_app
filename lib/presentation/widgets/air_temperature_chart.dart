import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:intl/intl.dart';

class AirTemperatureChart extends StatelessWidget {
  final List<SensorData> data;

  const AirTemperatureChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Filter data to show only one point per hour for better visualization
    final filteredData = <SensorData>[];
    DateTime? lastHour;
    
    for (final point in data) {
      final currentHour = DateTime(
        point.timestamp.year,
        point.timestamp.month,
        point.timestamp.day,
        point.timestamp.hour,
      );
      
      if (lastHour == null || currentHour != lastHour) {
        filteredData.add(point);
        lastHour = currentHour;
      }
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 12,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < filteredData.length) {
                    final date = filteredData[value.toInt()].timestamp;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°C',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: filteredData.length.toDouble() - 1,
          minY: 0,
          maxY: 30,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(filteredData.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  filteredData[index].airTemperature,
                );
              }),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [
                  Colors.orange,
                  Colors.red,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.red.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  final date = filteredData[index].timestamp;
                  return LineTooltipItem(
                    '${DateFormat('MM/dd HH:mm').format(date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: '${barSpot.y.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
