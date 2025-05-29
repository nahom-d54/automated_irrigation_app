part of 'sensor_data_bloc.dart';
abstract class SensorDataState extends Equatable {
  @override
  List<Object> get props => [];
}

class SensorDataInitial extends SensorDataState {}

class SensorDataLoading extends SensorDataState {}

class SensorDataRefreshing extends SensorDataState {
  final List<SensorData> currentData;
  
  SensorDataRefreshing(this.currentData);
  
  @override
  List<Object> get props => [currentData];
}

class SensorDataLoaded extends SensorDataState {
  final List<SensorData> sensorData;
  final ConnectionStatus connectionStatus;
  final String? socketId;
  final int dataCount;
  final DateTime lastUpdated;

  SensorDataLoaded(
    this.sensorData, {
    this.connectionStatus = ConnectionStatus.disconnected,
    this.socketId,
    required this.dataCount,
    required this.lastUpdated,
  });

  SensorDataLoaded copyWith({
    List<SensorData>? sensorData,
    ConnectionStatus? connectionStatus,
    String? socketId,
    int? dataCount,
    DateTime? lastUpdated,
  }) {
    return SensorDataLoaded(
      sensorData ?? this.sensorData,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      socketId: socketId ?? this.socketId,
      dataCount: dataCount ?? this.dataCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object> get props => [sensorData, connectionStatus, socketId ?? '', dataCount, lastUpdated];
}

class SensorDataError extends SensorDataState {
  final String message;
  final ConnectionStatus connectionStatus;

  SensorDataError(this.message, {this.connectionStatus = ConnectionStatus.disconnected});

  @override
  List<Object> get props => [message, connectionStatus];
}

class IrrigationTriggered extends SensorDataState {
  final String zone;
  final int duration;
  final DateTime timestamp;

  IrrigationTriggered({
    required this.zone,
    required this.duration,
    required this.timestamp,
  });

  @override
  List<Object> get props => [zone, duration, timestamp];
} 