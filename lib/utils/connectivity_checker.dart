import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final Function(bool) _onConnectivityChanged;
  
  ConnectivityChecker(this._onConnectivityChanged);
  
  Future<void> initialize() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _handleConnectivityChange(connectivityResult);
    
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> result) {
    final isConnected = result.first != ConnectivityResult.none;
    _onConnectivityChanged(isConnected);
  }
  
  void dispose() {
    _subscription?.cancel();
  }
}
