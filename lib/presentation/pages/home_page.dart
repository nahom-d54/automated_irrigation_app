import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/domain/entities/sensor_data.dart';
import 'package:irrigation_app/presentation/blocs/sensor_data/sensor_data_bloc.dart';
import 'package:irrigation_app/presentation/widgets/air_humidity_chart.dart';
import 'package:irrigation_app/presentation/widgets/air_temperature_chart.dart';
import 'package:irrigation_app/presentation/widgets/connection_status_indicator.dart';
import 'package:irrigation_app/presentation/widgets/sensor_status_card.dart';
import 'package:irrigation_app/presentation/widgets/soil_humidity_chart.dart';
import 'package:irrigation_app/presentation/widgets/soil_temperature_chart.dart';
import 'package:irrigation_app/presentation/widgets/summary_card.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';
import 'package:irrigation_app/presentation/widgets/environmental_data_chart.dart';
import 'package:intl/intl.dart';
import 'package:irrigation_app/presentation/widgets/data_export_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    final bloc=context.read<SensorDataBloc>();
    if(bloc.state is !SensorDataLoaded){
    bloc.add(LoadSensorData());

    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SensorDataBloc, SensorDataState>(
        builder: (context, state) {
          if (state is SensorDataInitial || state is SensorDataLoading) {
            return _buildLoadingState();
          } else if (state is SensorDataRefreshing) {
            return _buildContent(
              context,
              state.currentData,
              ConnectionStatus.connected,
              null,
              0,
              DateTime.now(),
              isRefreshing: true,
            );
          } else if (state is SensorDataLoaded) {
            final sensorData = state.sensorData;
            final latestData = sensorData.isNotEmpty ? sensorData.last : null;
            final connectionStatus = state.connectionStatus;
            
            return _buildContent(
              context,
              sensorData,
              connectionStatus,
              latestData,
              state.dataCount,
              state.lastUpdated,
              socketId: state.socketId,
            );
          } else if (state is SensorDataError) {
            return _buildErrorState(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade50,
            Colors.white,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading historical data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SensorDataError state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConnectionStatusIndicator(
                status: state.connectionStatus,
                onReconnectPressed: () {
                  context.read<SensorDataBloc>().add(ConnectSocket());
                },
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SensorDataBloc>().add(LoadSensorData());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<SensorData> sensorData,
    ConnectionStatus connectionStatus,
    dynamic latestData,
    int dataCount,
    DateTime lastUpdated, {
    String? socketId,
    bool isRefreshing = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade50,
            Colors.white,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<SensorDataBloc>().add(RefreshHistoricalData(days: 3));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              automaticallyImplyLeading: false,
              pinned: true,
              backgroundColor: Colors.green,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade700,
                        Colors.green.shade500,
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'Irrigation Monitor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    context.read<SensorDataBloc>().add(RefreshHistoricalData(days: 3));
                  },
                  tooltip: 'Refresh Historical Data',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            //            ConnectionStatusIndicator(
            //   status: connectionStatus,
            //   socketId: socketId,
            //   onReconnectPressed: () {
            //     context.read<SensorDataBloc>().add(ConnectSocket());
            //   },
            // ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Card(
                        key: ValueKey(isRefreshing),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.data_usage,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$dataCount data points loaded',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Last updated: ${DateFormat('MMM d, h:mm a').format(lastUpdated)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isRefreshing)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                 
                    if (latestData != null) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: SummaryCard(latestData: latestData),
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: SensorStatusCard(sensorData: latestData),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const DataExportWidget(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Air Temperature'),
                    const SizedBox(height: 8),
                    AirTemperatureChart(data: sensorData),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Air Humidity'),
                    const SizedBox(height: 8),
                    AirHumidityChart(data: sensorData),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Soil Humidity'),
                    const SizedBox(height: 8),
                    SoilHumidityChart(data: sensorData),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Soil Temperature'),
                    const SizedBox(height: 8),
                    SoilTemperatureChart(data: sensorData),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Environmental Data'),
                    const SizedBox(height: 8),
                    EnvironmentalDataChart(data: sensorData),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
