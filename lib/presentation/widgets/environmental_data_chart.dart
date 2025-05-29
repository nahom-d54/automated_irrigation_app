import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:intl/intl.dart';

class EnvironmentalDataChart extends StatelessWidget {
  final List<SensorData> data;

  const EnvironmentalDataChart({super.key, required this.data});

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
      height: 300,
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
            horizontalInterval: 10,
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
                interval: 10,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
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
          maxY: 120,
          lineBarsData: [
            // Wind Speed
            LineChartBarData(
              spots: List.generate(filteredData.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  filteredData[index].windSpeedKmh,
                );
              }),
              isCurved: true,
              color: Colors.cyan,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyan.withOpacity(0.1),
              ),
            ),
            // Pressure (scaled for visibility)
            LineChartBarData(
              spots: List.generate(filteredData.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  filteredData[index].pressureKPa,
                );
              }),
              isCurved: true,
              color: Colors.purple,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
            ),
            // Rainfall
            LineChartBarData(
              spots: List.generate(filteredData.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  filteredData[index].rainfall,
                );
              }),
              isCurved: false,
              color: Colors.indigo,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: filteredData[index].rainfall > 0 ? 4 : 0,
                  color: Colors.indigo,
                );
              }),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  final date = filteredData[index].timestamp;
                  final data = filteredData[index];
                  
                  String label = '';
                  String value = '';
                  
                  if (barSpot.barIndex == 0) {
                    label = 'Wind Speed';
                    value = '${barSpot.y.toStringAsFixed(1)} km/h';
                  } else if (barSpot.barIndex == 1) {
                    label = 'Pressure';
                    value = '${barSpot.y.toStringAsFixed(1)} kPa';
                  } else if (barSpot.barIndex == 2) {
                    label = 'Rainfall';
                    value = '${barSpot.y.toStringAsFixed(1)} mm';
                  }
                  
                  return LineTooltipItem(
                    '${DateFormat('MM/dd HH:mm').format(date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: '$label: $value',
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
