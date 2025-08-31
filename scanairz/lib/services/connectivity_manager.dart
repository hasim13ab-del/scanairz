import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityManager {
  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

  ConnectivityManager() {
    _init();
  }

  void _init() async {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      isConnected.value = result.isNotEmpty && result.first != ConnectivityResult.none;
    });
  }
}