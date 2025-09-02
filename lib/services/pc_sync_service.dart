import 'package:connectivity_plus/connectivity_plus.dart';

class PcSyncService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnectedToNetwork() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<bool> syncData(List<Map<String, dynamic>> data) async {
    // Simulate sync operation
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<bool> exportData(List<Map<String, dynamic>> data, String format) async {
    // Simulate export operation
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}