import 'dart:async';
import 'package:scanairz/models/scan_result.dart';

/// Bluetooth stub — full implementation coming in a future update.
class BluetoothConnector {
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => false;

  Future<List<dynamic>> getPairedDevices() async => [];
  Future<bool> connect(String macAddress) async => false;
  void disconnect() {}
  Future<void> syncData(List<ScanResult> scans) async {
    throw Exception('Bluetooth not yet supported.');
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
