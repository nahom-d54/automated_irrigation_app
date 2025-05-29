import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/presentation/blocs/sensor_data/sensor_data_bloc.dart';
import 'package:irrigation_app/services/data_export_service.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataExportService _exportService = DataExportService();

  // Export settings
  ExportFormat _selectedFormat = ExportFormat.csv;
  DateTime? _startDate;
  DateTime? _endDate;
  String _customFileName = '';
  
  // Filters
  double? _minAirTemperature;
  double? _maxAirTemperature;
  double? _minAirHumidity;
  double? _maxAirHumidity;
  double? _minSoilHumidity;
  double? _maxSoilHumidity;
  List<int> _selectedPredictions = [0, 1];
  bool _onlyWorkingSensors = false;
  
  // Field selection
  final Map<ExportField, bool> _selectedFields = {
    for (var field in ExportField.values) field: true,
  };
  
  // Export history
  List<String> _exportHistory = [];
  bool _isExporting = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExportHistory();
    _setDefaultDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 7)); // Default to last 7 days
  }

  Future<void> _loadExportHistory() async {
    final history = await _exportService.getExportHistory();
    setState(() {
      _exportHistory = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Settings'),
            Tab(text: 'Filters'),
            Tab(text: 'Fields'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isExporting ? null : _exportData,
            icon: _isExporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(),
          _buildFiltersTab(),
          _buildFieldsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Export Format'),
          Card(
            child: Column(
              children: [
                RadioListTile<ExportFormat>(
                  title: const Text('CSV (Comma Separated Values)'),
                  subtitle: const Text('Compatible with Excel, Google Sheets'),
                  value: ExportFormat.csv,
                  groupValue: _selectedFormat,
                  onChanged: (value) => setState(() => _selectedFormat = value!),
                  secondary: const Icon(Icons.table_chart, color: Colors.green),
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('JSON (JavaScript Object Notation)'),
                  subtitle: const Text('Structured data format for developers'),
                  value: ExportFormat.json,
                  groupValue: _selectedFormat,
                  onChanged: (value) => setState(() => _selectedFormat = value!),
                  secondary: const Icon(Icons.code, color: Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Date Range'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          'Start Date',
                          _startDate,
                          (date) => setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateSelector(
                          'End Date',
                          _endDate,
                          (date) => setState(() => _endDate = date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickDateButton('Last 24 Hours', () {
                          final now = DateTime.now();
                          setState(() {
                            _endDate = now;
                            _startDate = now.subtract(const Duration(days: 1));
                          });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickDateButton('Last 7 Days', () {
                          final now = DateTime.now();
                          setState(() {
                            _endDate = now;
                            _startDate = now.subtract(const Duration(days: 7));
                          });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickDateButton('Last 30 Days', () {
                          final now = DateTime.now();
                          setState(() {
                            _endDate = now;
                            _startDate = now.subtract(const Duration(days: 30));
                          });
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('File Name (Optional)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Custom file name',
                  hintText: 'Leave empty for auto-generated name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                onChanged: (value) => _customFileName = value,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDataPreview(),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Temperature Filters'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildRangeFilter(
                    'Air Temperature (°C)',
                    _minAirTemperature,
                    _maxAirTemperature,
                    -20.0,
                    60.0,
                    (min, max) => setState(() {
                      _minAirTemperature = min;
                      _maxAirTemperature = max;
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Humidity Filters'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildRangeFilter(
                    'Air Humidity (%)',
                    _minAirHumidity,
                    _maxAirHumidity,
                    0.0,
                    100.0,
                    (min, max) => setState(() {
                      _minAirHumidity = min;
                      _maxAirHumidity = max;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildRangeFilter(
                    'Soil Humidity (%)',
                    _minSoilHumidity,
                    _maxSoilHumidity,
                    0.0,
                    100.0,
                    (min, max) => setState(() {
                      _minSoilHumidity = min;
                      _maxSoilHumidity = max;
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('System Filters'),
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Only Working Sensors'),
                  subtitle: const Text('Include only data from functioning sensors'),
                  value: _onlyWorkingSensors,
                  onChanged: (value) => setState(() => _onlyWorkingSensors = value ?? false),
                  secondary: const Icon(Icons.sensors, color: Colors.green),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prediction Values',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: [0, 1].map((prediction) {
                          final isSelected = _selectedPredictions.contains(prediction);
                          return FilterChip(
                            label: Text(prediction == 1 ? 'Good (1)' : 'Alert (0)'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPredictions.add(prediction);
                                } else {
                                  _selectedPredictions.remove(prediction);
                                }
                              });
                            },
                            selectedColor: Colors.green.withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildClearFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildFieldsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        
        children: [
          _buildSectionHeader('Select Fields to Export'),

          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var field in ExportField.values) {
                      _selectedFields[field] = true;
                    }
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var field in ExportField.values) {
                      _selectedFields[field] = false;
                    }
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          Card(
            child: Column(
              children: ExportField.values.map((field) {
                return CheckboxListTile(
                  title: Text(_getFieldDisplayName(field)),
                  subtitle: Text(_getFieldDescription(field)),
                  value: _selectedFields[field] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _selectedFields[field] = value ?? false;
                    });
                  },
                  secondary: Icon(_getFieldIcon(field), color: Colors.green),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldSummary(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildSectionHeader('Export History'),
              const Spacer(),
              IconButton(
                onPressed: _loadExportHistory,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: _exportHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No export history',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Your exported files will appear here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _exportHistory.length,
                  itemBuilder: (context, index) {
                    final filePath = _exportHistory[index];
                    return _buildHistoryItem(filePath);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMM d, yyyy').format(date) : 'Select date',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildRangeFilter(
    String title,
    double? minValue,
    double? maxValue,
    double min,
    double max,
    Function(double?, double?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => onChanged(null, null),
              child: const Text('Clear'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: minValue?.toStringAsFixed(1) ?? '',
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  onChanged(parsed, maxValue);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: maxValue?.toStringAsFixed(1) ?? '',
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  onChanged(minValue, parsed);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClearFiltersButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _minAirTemperature = null;
            _maxAirTemperature = null;
            _minAirHumidity = null;
            _maxAirHumidity = null;
            _minSoilHumidity = null;
            _maxSoilHumidity = null;
            _selectedPredictions = [0, 1];
            _onlyWorkingSensors = false;
          });
        },
        icon: const Icon(Icons.clear),
        label: const Text('Clear All Filters'),
      ),
    );
  }

  Widget _buildFieldSummary() {
    final selectedCount = _selectedFields.values.where((selected) => selected).length;
    final totalCount = _selectedFields.length;
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$selectedCount of $totalCount fields selected for export',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    return BlocBuilder<SensorDataBloc, SensorDataState>(
      builder: (context, state) {
        if (state is SensorDataLoaded) {
          final filter = _createExportFilter();
          final filteredData = _filterDataForPreview(state.sensorData, filter);
          
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Total records available: ${state.sensorData.length}'),
                  Text('Records matching filters: ${filteredData.length}'),
                  if (_startDate != null && _endDate != null)
                    Text('Date range: ${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'),
                  const SizedBox(height: 8),
                  if (filteredData.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('No data matches the current filters'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHistoryItem(String filePath) {
    final file = File(filePath);
    final fileName = filePath.split('/').last;
    final isCSV = fileName.endsWith('.csv');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          isCSV ? Icons.table_chart : Icons.code,
          color: isCSV ? Colors.green : Colors.blue,
        ),
        title: Text(fileName),
        subtitle: FutureBuilder<FileStat>(
          future: file.stat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stat = snapshot.data!;
              return Text(
                '${_exportService.formatFileSize(stat.size)} • ${DateFormat('MMM d, yyyy h:mm a').format(stat.modified)}',
              );
            }
            return const Text('Loading...');
          },
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'share':
                await _exportService.shareExportedFile(filePath);
                break;
              case 'delete':
                _showDeleteConfirmation(filePath);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFieldDisplayName(ExportField field) {
    switch (field) {
      case ExportField.id:
        return 'Record ID';
      case ExportField.timestamp:
        return 'Timestamp';
      case ExportField.receivedAt:
        return 'Received At';
      case ExportField.createdAt:
        return 'Created At';
      case ExportField.updatedAt:
        return 'Updated At';
      case ExportField.airTemperature:
        return 'Air Temperature';
      case ExportField.airHumidity:
        return 'Air Humidity';
      case ExportField.soilTemperature:
        return 'Soil Temperature';
      case ExportField.soilHumidity:
        return 'Soil Humidity';
      case ExportField.soilMoisture:
        return 'Soil Moisture';
      case ExportField.windSpeed:
        return 'Wind Speed';
      case ExportField.rainfall:
        return 'Rainfall';
      case ExportField.pressure:
        return 'Atmospheric Pressure';
      case ExportField.workingSensors:
        return 'Working Sensors Count';
      case ExportField.prediction:
        return 'System Prediction';
    }
  }

  String _getFieldDescription(ExportField field) {
    switch (field) {
      case ExportField.id:
        return 'Unique identifier for each record';
      case ExportField.timestamp:
        return 'When the data was recorded';
      case ExportField.receivedAt:
        return 'When the data was received by server';
      case ExportField.createdAt:
        return 'When the record was created';
      case ExportField.updatedAt:
        return 'When the record was last updated';
      case ExportField.airTemperature:
        return 'Temperature in degrees Celsius';
      case ExportField.airHumidity:
        return 'Relative humidity percentage';
      case ExportField.soilTemperature:
        return 'Soil temperature in degrees Celsius';
      case ExportField.soilHumidity:
        return 'Soil moisture percentage';
      case ExportField.soilMoisture:
        return 'Soil moisture content percentage';
      case ExportField.windSpeed:
        return 'Wind speed in kilometers per hour';
      case ExportField.rainfall:
        return 'Rainfall amount in millimeters';
      case ExportField.pressure:
        return 'Atmospheric pressure in kilopascals';
      case ExportField.workingSensors:
        return 'Number of functioning sensors';
      case ExportField.prediction:
        return 'System prediction (0=Alert, 1=Good)';
    }
  }

  IconData _getFieldIcon(ExportField field) {
    switch (field) {
      case ExportField.id:
        return Icons.tag;
      case ExportField.timestamp:
      case ExportField.receivedAt:
      case ExportField.createdAt:
      case ExportField.updatedAt:
        return Icons.access_time;
      case ExportField.airTemperature:
      case ExportField.soilTemperature:
        return Icons.thermostat;
      case ExportField.airHumidity:
      case ExportField.soilHumidity:
      case ExportField.soilMoisture:
        return Icons.water_drop;
      case ExportField.windSpeed:
        return Icons.air;
      case ExportField.rainfall:
        return Icons.water;
      case ExportField.pressure:
        return Icons.compress;
      case ExportField.workingSensors:
        return Icons.sensors;
      case ExportField.prediction:
        return Icons.psychology;
    }
  }

  ExportFilter _createExportFilter() {
    return ExportFilter(
      startDate: _startDate,
      endDate: _endDate,
      minAirTemperature: _minAirTemperature,
      maxAirTemperature: _maxAirTemperature,
      minAirHumidity: _minAirHumidity,
      maxAirHumidity: _maxAirHumidity,
      minSoilHumidity: _minSoilHumidity,
      maxSoilHumidity: _maxSoilHumidity,
      predictions: _selectedPredictions.isNotEmpty ? _selectedPredictions : null,
      onlyWorkingSensors: _onlyWorkingSensors ? true : null,
      selectedFields: _selectedFields.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
    );
  }

  List<SensorData> _filterDataForPreview(List<SensorData> data, ExportFilter filter) {
    return data.where((item) {
      if (filter.startDate != null && item.timestamp.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && item.timestamp.isAfter(filter.endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _exportData() async {
    final state = context.read<SensorDataBloc>().state;
    if (state is! SensorDataLoaded) {
      _showErrorDialog('No data available for export');
      return;
    }

    if (_selectedFields.values.every((selected) => !selected)) {
      _showErrorDialog('Please select at least one field to export');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final filter = _createExportFilter();
      final result = await _exportService.exportData(
        data: state.sensorData,
        format: _selectedFormat,
        filter: filter,
        customFileName: _customFileName.isNotEmpty ? _customFileName : null,
      );

      setState(() {
        _isExporting = false;
      });

      if (result.success) {
        _showExportSuccessDialog(result);
        await _loadExportHistory();
      } else {
        _showErrorDialog(result.error ?? 'Export failed');
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _showExportSuccessDialog(ExportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Records exported: ${result.recordCount}'),
            Text('File size: ${_exportService.formatFileSize(result.fileSize)}'),
            if (result.filePath != null)
              Text('Location: ${result.filePath!.split('/').last}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (result.filePath != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportService.shareExportedFile(result.filePath!);
              },
              child: const Text('Share'),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Export Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String filePath) {
    final fileName = filePath.split('/').last;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Export File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _exportService.deleteExportFile(filePath);
              if (success) {
                await _loadExportHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
