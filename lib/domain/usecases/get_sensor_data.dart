import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:irrigation_app/domain/repositories/sensor_data_repository.dart';

class GetSensorData {
  final SensorDataRepository repository;

  GetSensorData(this.repository);

  Future<List<SensorData>> call() async {
    return await repository.getSensorData();
  }
}
