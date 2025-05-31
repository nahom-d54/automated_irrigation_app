import 'package:irrigation_app/data/datasources/sensor_data_local_source.dart';
import 'package:irrigation_app/data/datasources/sensor_data_http_source.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';
import 'package:irrigation_app/data/datasources/auth_data_source.dart';
import 'package:irrigation_app/data/repositories/sensor_data_repository_impl.dart';
import 'package:irrigation_app/data/repositories/auth_repository_impl.dart';
import 'package:irrigation_app/domain/repositories/sensor_data_repository.dart';
import 'package:irrigation_app/domain/repositories/auth_repository.dart';
import 'package:irrigation_app/presentation/blocs/sensor_data/sensor_data_bloc.dart';
import 'package:irrigation_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:irrigation_app/utils/connectivity_checker.dart';
import 'package:irrigation_app/presentation/blocs/notification/notification_bloc.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  final SensorDataLocalSource _localDataSource = SensorDataLocalSource();
  late final SensorDataHttpSource _httpDataSource;
  late final SensorDataSocketIOSource _socketIOSource;
  late final AuthDataSource _authDataSource;
  late final SensorDataRepository _sensorRepository;
  late final AuthRepository _authRepository;
  late final SensorDataBloc _sensorDataBloc;
  late final AuthBloc _authBloc;
  late final NotificationBloc _notificationBloc;
  late final ConnectivityChecker _connectivityChecker;

  void initialize() {
    // Initialize data sources
    _authDataSource = AuthDataSource();
    _httpDataSource = SensorDataHttpSource(_authDataSource);
    _socketIOSource = SensorDataSocketIOSource(_authDataSource);

    // Initialize repositories
    _sensorRepository = SensorDataRepositoryImpl(
      localDataSource: _localDataSource,
      httpDataSource: _httpDataSource,
      socketIOSource: _socketIOSource,
    );

    _authRepository = AuthRepositoryImpl(
      authDataSource: _authDataSource,
    );

    // Initialize BLoCs
    _sensorDataBloc = SensorDataBloc(repository: _sensorRepository);
    _authBloc = AuthBloc(
        authRepository: _authRepository,
        authDataSource: _authDataSource,
        socket: _socketIOSource);
    _notificationBloc = NotificationBloc();

    // Initialize connectivity checker
    _connectivityChecker = ConnectivityChecker((isConnected) {
      if (isConnected) {
        _sensorDataBloc.add(ConnectSocket());
      } else {
        _sensorDataBloc.add(DisconnectSocket());
      }
    });

    _connectivityChecker.initialize();
  }

  SensorDataBloc get sensorDataBloc => _sensorDataBloc;
  AuthBloc get authBloc => _authBloc;
  NotificationBloc get notificationBloc => _notificationBloc;

  void dispose() {
    _sensorDataBloc.close();
    _authBloc.close();
    _notificationBloc.close();
    _socketIOSource.dispose();
    _httpDataSource.dispose();
    _authDataSource.dispose();
    _connectivityChecker.dispose();
  }
}
