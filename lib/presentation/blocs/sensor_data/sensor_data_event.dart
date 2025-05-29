part of 'sensor_data_bloc.dart';

abstract class SensorDataEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadSensorData extends SensorDataEvent {}

class RefreshHistoricalData extends SensorDataEvent {
  final int days;
  
  RefreshHistoricalData({this.days = 3});
  
  @override
  List<Object> get props => [days];
}

class ConnectSocket extends SensorDataEvent {}

class DisconnectSocket extends SensorDataEvent {}

class RequestSensorData extends SensorDataEvent {
  final int days;
  
  RequestSensorData({this.days = 3});
  
  @override
  List<Object> get props => [days];
}

class TriggerIrrigation extends SensorDataEvent {
  final String zone;
  final int duration;
  
  TriggerIrrigation({required this.zone, required this.duration});
  
  @override
  List<Object> get props => [zone, duration];
}

class UpdateSensorData extends SensorDataEvent {
  final List<SensorData> sensorData;

  UpdateSensorData(this.sensorData);

  @override
  List<Object> get props => [sensorData];
}

class ConnectionStatusChanged extends SensorDataEvent {
  final ConnectionStatus status;

  ConnectionStatusChanged(this.status);

  @override
  List<Object> get props => [status];
} 