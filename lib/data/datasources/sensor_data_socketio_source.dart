import 'dart:async';
import 'package:irrigation_app/data/datasources/auth_data_source.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:irrigation_app/data/models/sensor_data_model.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class SensorDataSocketIOSource {
  final String _serverUrl;
  IO.Socket? _socket;
  final StreamController<List<SensorDataModel>> _dataStreamController = StreamController<List<SensorDataModel>>.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  bool _isDisposed = false;
  List<SensorDataModel> _historicalData = [];

  final AuthDataSource dataSource;
  
  SensorDataSocketIOSource(this.dataSource, {
    String serverUrl = 'https://integrated.ai.astu.pro.et',
  }) : _serverUrl = serverUrl {
    _connectionStatusController.add(ConnectionStatus.disconnected);
  }

  Stream<List<SensorDataModel>> get dataStream => _dataStreamController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  
  Future<void> connect() async {
    if (_isDisposed) return;
    
    if (_socket != null) {
      await disconnect();
    }
    
    try {
      _connectionStatusController.add(ConnectionStatus.connecting);
      final token= await dataSource.getAccessToken();
      _socket = IO.io(_serverUrl, 
      IO.OptionBuilder()
          .setTransports(['websocket']) 
          .enableAutoConnect() 
          .enableReconnection() 
          .setReconnectionAttempts(5) 
          .setAuth({
            'token':token
          })
          .setReconnectionDelay(1000) 
          .setReconnectionDelayMax(5000) 
          .setTimeout(20000) 
          .build());
      
      _setupSocketListeners();
      
      _socket!.connect();
      
    } catch (e) {
      print('Socket.IO connection error: $e');
      _connectionStatusController.add(ConnectionStatus.error);
    }
  }
  
  void _setupSocketListeners() {
    if (_socket == null) return;
    
    // Connection events
    _socket!.onConnect((_) {
      print('Socket.IO connected');
      _connectionStatusController.add(ConnectionStatus.connected);
      
      // Join the sensor data room
      _socket!.emit('join_sensor_room', {'room': 'irrigation_sensors'});
    });
    
    _socket!.onDisconnect((_) {
      print('Socket.IO disconnected');
      if (!_isDisposed) {
        _connectionStatusController.add(ConnectionStatus.disconnected);
      }
    });
    
    _socket!.onConnectError((error) {
      print('Socket.IO connection error: $error');
      _connectionStatusController.add(ConnectionStatus.error);
    });
    
    _socket!.onError((error) {
      print('Socket.IO error: $error');
      _connectionStatusController.add(ConnectionStatus.error);
    });
    
    // Data events - handle real-time updates
    _socket!.on('sensor_data_update', (data) {
      _handleSingleUpdate(data);
    });
    
    _socket!.on('new_sensor_data', (data) {
      _handleSingleUpdate(data);
    });
    
    _socket!.on('sensor_reading', (data) {
      _handleSingleUpdate(data);
    });
    
    // Reconnection events
    _socket!.onReconnect((attempt) {
      print('Socket.IO reconnected on attempt: $attempt');
      _connectionStatusController.add(ConnectionStatus.connected);
    });
    
    _socket!.onReconnectAttempt((attempt) {
      print('Socket.IO reconnection attempt: $attempt');
      _connectionStatusController.add(ConnectionStatus.connecting);
    });
    
    _socket!.onReconnectError((error) {
      print('Socket.IO reconnection error: $error');
      _connectionStatusController.add(ConnectionStatus.error);
    });
    
    _socket!.onReconnectFailed((_) {
      print('Socket.IO reconnection failed');
      _connectionStatusController.add(ConnectionStatus.error);
    });
  }
  
  void _handleSingleUpdate(dynamic data) {
    try {
      print('Received real-time sensor data: $data');
      
      final sensorData = SensorDataModel.fromJson(data);
      
      // Check if this data already exists (by ID or timestamp)
      final existingIndex = _historicalData.indexWhere((item) => 
        item.id == sensorData.id || 
        item.timestamp.isAtSameMomentAs(sensorData.timestamp)
      );
      
      if (existingIndex != -1) {
        // Update existing data
        _historicalData[existingIndex] = sensorData;
        print('Updated existing sensor data with ID: ${sensorData.id}');
      } else {
        // Add new data
        _historicalData.add(sensorData);
        print('Added new sensor data with ID: ${sensorData.id}');
      }
      
      // Keep only the last 7 days of data to prevent memory issues
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      _historicalData = _historicalData.where((data) => 
        data.timestamp.isAfter(sevenDaysAgo)
      ).toList();
      
      // Sort by timestamp (oldest first)
      _historicalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('Total sensor data points: ${_historicalData.length}');
      _dataStreamController.add(List.from(_historicalData));
      
    } catch (e) {
      print('Error parsing real-time sensor update: $e');
    }
  }
  
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    if (!_isDisposed) {
      _connectionStatusController.add(ConnectionStatus.disconnected);
    }
  }
  
  void dispose() {
    _isDisposed = true;
    disconnect();
    _dataStreamController.close();
    _connectionStatusController.close();
  }
  
  // Set historical data from HTTP API
  void setHistoricalData(List<SensorDataModel> historicalData) {
    print(historicalData);
    _historicalData = List.from(historicalData);
    _historicalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    print('Set ${_historicalData.length} historical data points');
    _dataStreamController.add(List.from(_historicalData));
  }
  
  // Get current data count
  int get dataCount => _historicalData.length;
  
  // Get latest data point
  SensorDataModel? get latestData => _historicalData.isNotEmpty ? _historicalData.last : null;
  
  // Send commands to the server
  void sendCommand(String event, Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    }
  }
  
  // Send irrigation command
  void triggerIrrigation({required String zone, required int duration}) {
    sendCommand('trigger_irrigation', {
      'zone': zone,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Get connection info
  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;
}
