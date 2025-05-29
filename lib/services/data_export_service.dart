import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:intl/intl.dart';

enum ExportFormat { csv, json }

enum ExportField {
  id,
  timestamp,
  receivedAt,
  createdAt,
  updatedAt,
  airTemperature,
  airHumidity,
  soilTemperature,
  soilHumidity,
  soilMoisture,
  windSpeed,
  rainfall,
  pressure,
  workingSensors,
  prediction,
}

class ExportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAirTemperature;
  final double? maxAirTemperature;
  final double? minAirHumidity;
  final double? maxAirHumidity;
  final double? minSoilHumidity;
  final double? maxSoilHumidity;
  final List<int>? predictions;
  final bool? onlyWorkingSensors;
  final List<ExportField> selectedFields;

  ExportFilter({
    this.startDate,
    this.endDate,
    this.minAirTemperature,
    this.maxAirTemperature,
    this.minAirHumidity,
    this.maxAirHumidity,
    this.minSoilHumidity,
    this.maxSoilHumidity,
    this.predictions,
    this.onlyWorkingSensors,
    this.selectedFields = const [],
  });
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int recordCount;
  final int fileSize;

  ExportResult({
    required this.success,
    this.filePath,
    this.error,
    required this.recordCount,
    required this.fileSize,
  });
}

class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  Future<ExportResult> exportData({
    required List<SensorData> data,
    required ExportFormat format,
    required ExportFilter filter,
    String? customFileName,
  }) async {
    try {
      // Request storage permission
      final permission = await _requestStoragePermission();
      if (!permission) {
        return ExportResult(
          success: false,
          error: 'Storage permission denied',
          recordCount: 0,
          fileSize: 0,
        );
      }

      // Filter data
      final filteredData = _filterData(data, filter);
      
      if (filteredData.isEmpty) {
        return ExportResult(
          success: false,
          error: 'No data matches the selected filters',
          recordCount: 0,
          fileSize: 0,
        );
      }

      // Generate filename
      final fileName = customFileName ?? _generateFileName(format, filter);
      
      // Export based on format
      String content;
      String fileExtension;
      
      switch (format) {
        case ExportFormat.csv:
          content = _generateCSV(filteredData, filter.selectedFields);
          fileExtension = 'csv';
          break;
        case ExportFormat.json:
          content = _generateJSON(filteredData, filter.selectedFields);
          fileExtension = 'json';
          break;
      }

      // Save file
      final filePath = await _saveFile(content, '$fileName.$fileExtension');
      final fileSize = content.length;

      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: filteredData.length,
        fileSize: fileSize,
      );

    } catch (e) {
      return ExportResult(
        success: false,
        error: e.toString(),
        recordCount: 0,
        fileSize: 0,
      );
    }
  }

  Future<bool> shareExportedFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
      return true;
    } catch (e) {
      print('Error sharing file: $e');
      return false;
    }
  }

  List<SensorData> _filterData(List<SensorData> data, ExportFilter filter) {
    return data.where((item) {
      // Date range filter
      if (filter.startDate != null && item.timestamp.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && item.timestamp.isAfter(filter.endDate!)) {
        return false;
      }

      // Temperature filters
      if (filter.minAirTemperature != null && item.airTemperatureC < filter.minAirTemperature!) {
        return false;
      }
      if (filter.maxAirTemperature != null && item.airTemperatureC > filter.maxAirTemperature!) {
        return false;
      }

      // Humidity filters
      if (filter.minAirHumidity != null && item.airHumidity < filter.minAirHumidity!) {
        return false;
      }
      if (filter.maxAirHumidity != null && item.airHumidity > filter.maxAirHumidity!) {
        return false;
      }
      if (filter.minSoilHumidity != null && item.soilHumidity < filter.minSoilHumidity!) {
        return false;
      }
      if (filter.maxSoilHumidity != null && item.soilHumidity > filter.maxSoilHumidity!) {
        return false;
      }

      // Prediction filter
      if (filter.predictions != null && !filter.predictions!.contains(item.prediction)) {
        return false;
      }

      // Working sensors filter
      if (filter.onlyWorkingSensors == true && !item.sensorWorking) {
        return false;
      }

      return true;
    }).toList();
  }

  String _generateCSV(List<SensorData> data, List<ExportField> selectedFields) {
    final fields = selectedFields.isNotEmpty ? selectedFields : ExportField.values;
    
    // Generate headers
    final headers = fields.map((field) => _getFieldDisplayName(field)).toList();
    
    // Generate rows
    final rows = data.map((item) {
      return fields.map((field) => _getFieldValue(item, field)).toList();
    }).toList();

    // Combine headers and rows
    final csvData = [headers, ...rows];
    
    return const ListToCsvConverter().convert(csvData);
  }

  String _generateJSON(List<SensorData> data, List<ExportField> selectedFields) {
    final fields = selectedFields.isNotEmpty ? selectedFields : ExportField.values;
    
    final jsonData = {
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'record_count': data.length,
        'fields': fields.map((f) => f.name).toList(),
        'date_range': {
          'start': data.isNotEmpty ? data.first.timestamp.toIso8601String() : null,
          'end': data.isNotEmpty ? data.last.timestamp.toIso8601String() : null,
        },
      },
      'data': data.map((item) {
        final record = <String, dynamic>{};
        for (final field in fields) {
          record[field.name] = _getFieldValue(item, field);
        }
        return record;
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  String _getFieldDisplayName(ExportField field) {
    switch (field) {
      case ExportField.id:
        return 'ID';
      case ExportField.timestamp:
        return 'Timestamp';
      case ExportField.receivedAt:
        return 'Received At';
      case ExportField.createdAt:
        return 'Created At';
      case ExportField.updatedAt:
        return 'Updated At';
      case ExportField.airTemperature:
        return 'Air Temperature (°C)';
      case ExportField.airHumidity:
        return 'Air Humidity (%)';
      case ExportField.soilTemperature:
        return 'Soil Temperature (°C)';
      case ExportField.soilHumidity:
        return 'Soil Humidity (%)';
      case ExportField.soilMoisture:
        return 'Soil Moisture (%)';
      case ExportField.windSpeed:
        return 'Wind Speed (km/h)';
      case ExportField.rainfall:
        return 'Rainfall (mm)';
      case ExportField.pressure:
        return 'Pressure (kPa)';
      case ExportField.workingSensors:
        return 'Working Sensors';
      case ExportField.prediction:
        return 'Prediction';
    }
  }

  dynamic _getFieldValue(SensorData item, ExportField field) {
    switch (field) {
      case ExportField.id:
        return item.id;
      case ExportField.timestamp:
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp);
      case ExportField.receivedAt:
        return item.receivedAt != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(item.receivedAt!)
            : '';
      case ExportField.createdAt:
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(item.createdAt);
      case ExportField.updatedAt:
        return item.updatedAt != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(item.updatedAt!)
            : '';
      case ExportField.airTemperature:
        return item.airTemperatureC.toStringAsFixed(2);
      case ExportField.airHumidity:
        return item.airHumidity.toStringAsFixed(2);
      case ExportField.soilTemperature:
        return item.soilTemperature.toStringAsFixed(2);
      case ExportField.soilHumidity:
        return item.soilHumidity.toStringAsFixed(2);
      case ExportField.soilMoisture:
        return item.soilMoisture.toStringAsFixed(2);
      case ExportField.windSpeed:
        return item.windSpeedKmh.toStringAsFixed(2);
      case ExportField.rainfall:
        return item.rainfall.toStringAsFixed(2);
      case ExportField.pressure:
        return item.pressureKPa.toStringAsFixed(2);
      case ExportField.workingSensors:
        return item.numberOfWorkingSensors.toInt();
      case ExportField.prediction:
        return item.prediction;
    }
  }

  String _generateFileName(ExportFormat format, ExportFilter filter) {
    final dateFormat = DateFormat('yyyyMMdd');
    final timeFormat = DateFormat('HHmmss');
    final now = DateTime.now();
    
    String baseName = 'irrigation_data';
    
    if (filter.startDate != null && filter.endDate != null) {
      baseName += '_${dateFormat.format(filter.startDate!)}_to_${dateFormat.format(filter.endDate!)}';
    } else if (filter.startDate != null) {
      baseName += '_from_${dateFormat.format(filter.startDate!)}';
    } else if (filter.endDate != null) {
      baseName += '_until_${dateFormat.format(filter.endDate!)}';
    }
    
    baseName += '_${dateFormat.format(now)}_${timeFormat.format(now)}';
    
    return baseName;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  Future<String> _saveFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file.path;
  }

  Future<List<String>> getExportHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .where((file) => file.path.endsWith('.csv') || file.path.endsWith('.json'))
          .map((file) => file.path)
          .toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) {
        final fileA = File(a);
        final fileB = File(b);
        return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
      });
      
      return files;
    } catch (e) {
      print('Error getting export history: $e');
      return [];
    }
  }

  Future<bool> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting export file: $e');
      return false;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
