import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/presentation/blocs/sensor_data/sensor_data_bloc.dart';
import 'package:irrigation_app/presentation/pages/data_export_page.dart';
import 'package:irrigation_app/services/data_export_service.dart';

class DataExportWidget extends StatelessWidget {
  const DataExportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SensorDataBloc, SensorDataState>(
      builder: (context, state) {
        if (state is SensorDataLoaded) {
          return _buildExportCard(context, state.sensorData.length);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildExportCard(BuildContext context, int dataCount) {
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
              children: [
                const Icon(Icons.download, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DataExportPage(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$dataCount records available for export',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickExportButton(
                    context,
                    'CSV Export',
                    'Last 7 days',
                    Icons.table_chart,
                    Colors.green,
                    () => _quickExport(context, ExportFormat.csv),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickExportButton(
                    context,
                    'JSON Export',
                    'Last 7 days',
                    Icons.code,
                    Colors.blue,
                    () => _quickExport(context, ExportFormat.json),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickExport(BuildContext context, ExportFormat format) async {
    final state = context.read<SensorDataBloc>().state;
    if (state is! SensorDataLoaded) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting data...'),
          ],
        ),
      ),
    );

    try {
      final exportService = DataExportService();
      final now = DateTime.now();
      final filter = ExportFilter(
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
        selectedFields: [], // Use all fields
      );

      final result = await exportService.exportData(
        data: state.sensorData,
        format: format,
        filter: filter,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success && context.mounted) {
        // Show success and offer to share
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Export Complete'),
              ],
            ),
            content: Text('${result.recordCount} records exported successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              if (result.filePath != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    exportService.shareExportedFile(result.filePath!);
                  },
                  child: const Text('Share'),
                ),
            ],
          ),
        );
      } else if (context.mounted) {
        // Show error
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
            content: Text(result.error ?? 'Unknown error occurred'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error
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
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
