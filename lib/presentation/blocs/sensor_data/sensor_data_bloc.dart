 import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:irrigation_app/domain/repositories/sensor_data_repository.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';
import 'package:irrigation_app/services/sensor_monitoring_service.dart';

part 'sensor_data_state.dart';
part 'sensor_data_event.dart';



// BLoC
class SensorDataBloc extends Bloc<SensorDataEvent, SensorDataState> {
  final SensorDataRepository repository;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;
  final SensorMonitoringService _monitoringService = SensorMonitoringService();

  SensorDataBloc({required this.repository}) : super(SensorDataInitial()) {
    on<LoadSensorData>(_onLoadSensorData);
    on<RefreshHistoricalData>(_onRefreshHistoricalData);
    on<UpdateSensorData>(_onUpdateSensorData);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<RequestSensorData>(_onRequestSensorData);
    on<TriggerIrrigation>(_onTriggerIrrigation);
    
    // Initialize monitoring service
    _monitoringService.initialize();
  }

  Future<void> _onLoadSensorData(
    LoadSensorData event,
    Emitter<SensorDataState> emit,
  ) async {
    emit(SensorDataLoading());
    try {
      final data = await repository.getSensorData();
      emit(SensorDataLoaded(
        data,
        socketId: repository.socketId,
        dataCount: repository.dataCount,
        lastUpdated: DateTime.now(),
      ));
      
      // Listen to real-time updates
      _dataSubscription?.cancel();
      _dataSubscription = repository.getSensorDataStream().listen(
        (data) {
          add(UpdateSensorData(data));
        },
      );
      
      // Listen to connection status changes
      _connectionSubscription?.cancel();
      _connectionSubscription = repository.getConnectionStatus().listen(
        (status) {
          add(ConnectionStatusChanged(status));
        },
      );
      
    } catch (e) {
      emit(SensorDataError(e.toString()));
    }
  }

  Future<void> _onRefreshHistoricalData(
    RefreshHistoricalData event,
    Emitter<SensorDataState> emit,
  ) async {
    try {
       emit(SensorDataRefreshing([]));
        await repository.refreshHistoricalData(days: event.days);
      final data = await repository.getSensorData();
         emit(SensorDataLoaded(
        data,
        socketId: repository.socketId,
        dataCount: repository.dataCount,
        lastUpdated: DateTime.now(),
      ));
        // The updated data will come through the stream
      } catch (e) {
        emit(SensorDataError('Failed to refresh historical data: $e'));
      }
    if (state is SensorDataLoaded) {
      final currentState = state as SensorDataLoaded;
      emit(SensorDataRefreshing(currentState.sensorData));
      
      
    }
  }

  Future<void> _onUpdateSensorData(
    UpdateSensorData event,
    Emitter<SensorDataState> emit,
  ) async {
    if (state is SensorDataLoaded || state is SensorDataRefreshing) {
      // Process latest sensor data for monitoring
      if (event.sensorData.isNotEmpty) {
        await _monitoringService.processSensorData(event.sensorData.last);
      }
      
      emit(SensorDataLoaded(
        event.sensorData,
        connectionStatus: state is SensorDataLoaded 
            ? (state as SensorDataLoaded).connectionStatus 
            : ConnectionStatus.connected,
        socketId: repository.socketId,
        dataCount: repository.dataCount,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> _onConnectionStatusChanged(
    ConnectionStatusChanged event,
    Emitter<SensorDataState> emit,
  ) async {
    if (state is SensorDataLoaded) {
      final currentState = state as SensorDataLoaded;
      emit(currentState.copyWith(
        connectionStatus: event.status,
        socketId: repository.socketId,
      ));
    } else if (state is SensorDataError) {
      final currentState = state as SensorDataError;
      emit(SensorDataError(currentState.message, connectionStatus: event.status));
    }
  }

  Future<void> _onConnectSocket(
    ConnectSocket event,
    Emitter<SensorDataState> emit,
  ) async {
    await repository.connectSocket();
  }

  Future<void> _onDisconnectSocket(
    DisconnectSocket event,
    Emitter<SensorDataState> emit,
  ) async {
    await repository.disconnectSocket();
  }

  Future<void> _onRequestSensorData(
    RequestSensorData event,
    Emitter<SensorDataState> emit,
  ) async {
    add(RefreshHistoricalData(days: event.days));
  }

  Future<void> _onTriggerIrrigation(
    TriggerIrrigation event,
    Emitter<SensorDataState> emit,
  ) async {
    try {
      repository.triggerIrrigation(zone: event.zone, duration: event.duration);
      
      // Send success notification
      await _monitoringService.sendIrrigationAlert(event.zone, event.duration, true);
      
      emit(IrrigationTriggered(
        zone: event.zone,
        duration: event.duration,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      // Send failure notification
      await _monitoringService.sendIrrigationAlert(event.zone, event.duration, false);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}