import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';

abstract class SensorDataRepository {
  Future<List<SensorData>> getSensorData();
  Stream<List<SensorData>> getSensorDataStream();
  Stream<ConnectionStatus> getConnectionStatus();
  Future<void> connectSocket();
  Future<void> disconnectSocket();
  Future<void> refreshHistoricalData({int days = 3});
  Future<List<SensorData>> getHistoricalData({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  void triggerIrrigation({required String zone, required int duration});
  bool get isConnected;
  String? get socketId;
  int get dataCount;
  SensorData? get latestData;
}
