import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:irrigation_app/data/models/sensor_data_model.dart';

class SensorDataHttpSource {
  final String baseUrl;
  final http.Client httpClient;

  SensorDataHttpSource({
    this.baseUrl = 'https://integrated.ai.astu.pro.et',
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<List<SensorDataModel>> getHistoricalSensorData({
    int? limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final uri = Uri.parse(
          'https://integrated.ai.astu.pro.et/api/system/get_sensordata');

      // Add query parameters if provided
      final queryParams = <String, String>{};
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final finalUri = queryParams.isNotEmpty
          ? uri.replace(queryParameters: queryParams)
          : uri;

      print('Fetching historical data from: $finalUri');

      final response = await httpClient.get(
        finalUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timeout: Failed to fetch data within 30 seconds');
        },
      );

      print('HTTP Response Status: ${response.statusCode}');
      print(
          'HTTP Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Handle different response formats
        List<dynamic> results = [];

        if (jsonData.containsKey('results')) {
          results = jsonData['results'] as List<dynamic>;
        } else if (jsonData.containsKey('data')) {
          results = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List) {
          results = jsonData as List;
        } else {
          throw Exception('Unexpected response format: ${jsonData.keys}');
        }

        final List<SensorDataModel> sensorDataList = results
            .map((item) =>
                SensorDataModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Sort by timestamp (oldest first)
        sensorDataList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        print(
            'Successfully parsed ${sensorDataList.length} historical records');
        return sensorDataList;
      } else {
        throw Exception(
            'Failed to load sensor data: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching historical sensor data: $e');
      rethrow;
    }
  }

  Future<List<SensorDataModel>> getRecentSensorData({int days = 3}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return getHistoricalSensorData(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<SensorDataModel> getLatestSensorData() async {
    try {
      final uri = Uri.parse(
          'https://integrated.ai.astu.pro.et/api/system/get_sensordata/last');

      print('Fetching latest sensor data from: $uri');

      final response = await httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timeout: Failed to fetch latest data within 30 seconds');
        },
      );

      print('HTTP Response Status: ${response.statusCode}');
      print(
          'HTTP Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData.containsKey('results')) {
          final item = jsonData['results'] as Map<String, dynamic>;
          return SensorDataModel.fromJson(item);
        } else {
          throw Exception(
              'Unexpected response format for latest data: ${jsonData.keys}');
        }
      } else {
        throw Exception(
            'Failed to load latest sensor data: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching latest sensor data: $e');
      rethrow;
    }
  }

  void dispose() {
    httpClient.close();
  }
}
