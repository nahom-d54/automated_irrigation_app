import 'package:irrigation_app/data/datasources/sensor_data_local_source.dart';
import 'package:irrigation_app/data/datasources/sensor_data_http_source.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:irrigation_app/domain/repositories/sensor_data_repository.dart';

class SensorDataRepositoryImpl implements SensorDataRepository {
  final SensorDataLocalSource localDataSource;
  final SensorDataHttpSource httpDataSource;
  final SensorDataSocketIOSource socketIOSource;
  bool _isInitialized = false;

  SensorDataRepositoryImpl({
    required this.localDataSource,
    required this.httpDataSource,
    required this.socketIOSource,
  });

  @override
  Future<List<SensorData>> getSensorData() async {
    try {
      print('Fetching historical sensor data from API...');
      
      // First, try to get historical data from the API
      final historicalData = await httpDataSource.getRecentSensorData(days: 3);
      
      if (historicalData.isNotEmpty) {
        print('Successfully fetched ${historicalData.length} historical records from API');
        
        // Set historical data in Socket.IO source
        socketIOSource.setHistoricalData(historicalData);
        
        // Connect to Socket.IO for real-time updates
        if (!_isInitialized) {
          socketIOSource.connect();
          _isInitialized = true;
        }
        
        return historicalData;
      } else {
        print('No historical data from API, falling back to local data');
        throw Exception('No historical data available from API');
      }
      
    } catch (e) {
      print('Error fetching from API: $e');
      print('Falling back to local dummy data...');
      
      // Fallback to local data if API fails
      final localData = await localDataSource.getSensorData();
      
      // Set local data in Socket.IO source
      socketIOSource.setHistoricalData(localData);
      
      // Still try to connect to Socket.IO for real-time updates
      if (!_isInitialized) {
        socketIOSource.connect();
        _isInitialized = true;
      }
      
      return localData;
    }
  }
  
  @override
  Stream<List<SensorData>> getSensorDataStream() {
    return socketIOSource.dataStream;
  }
  
  @override
  Stream<ConnectionStatus> getConnectionStatus() {
    return socketIOSource.connectionStatus;
  }
  
  @override
  Future<void> connectSocket() async {
    await socketIOSource.connect();
  }
  
  @override
  Future<void> disconnectSocket() async {
    await socketIOSource.disconnect();
  }
  
  @override
  Future<void> refreshHistoricalData({int days = 3}) async {
    
    try {
      print('Refreshing historical data...');
      final historicalData = await httpDataSource.getRecentSensorData(days: days);
      socketIOSource.setHistoricalData(historicalData);
      print('Historical data refreshed successfully');
    } catch (e) {
      print('Error refreshing historical data: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<SensorData>> getHistoricalData({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await httpDataSource.getHistoricalSensorData(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }
  
  @override
  void triggerIrrigation({required String zone, required int duration}) {
    socketIOSource.triggerIrrigation(zone: zone, duration: duration);
  }
  
  @override
  bool get isConnected => socketIOSource.isConnected;
  
  @override
  String? get socketId => socketIOSource.socketId;
  
  @override
  int get dataCount => socketIOSource.dataCount;
  
  @override
  SensorData? get latestData => socketIOSource.latestData;
}
