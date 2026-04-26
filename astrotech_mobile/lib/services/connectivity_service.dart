import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _isConnectedSingle(result);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _connectivityController.add(_isConnectedSingle(result));
    } catch (e) {
      _connectivityController.add(false);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectivityController.add(_isConnectedSingle(result));
  }

  bool _isConnectedSingle(ConnectivityResult result) {
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet;
  }

  void dispose() {
    _connectivityController.close();
  }
}
