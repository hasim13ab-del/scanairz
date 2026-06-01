import 'dart:async';
import 'package:scanairz/models/scan_result.dart';

/// USB stub — full implementation coming in a future update.
class UsbConnector {
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => false;

  Future<List<dynamic>> getDevices() async => [];
  Future<bool> connect(dynamic device) async => false;
  Future<void> disconnect() async {}
  Future<void> syncData(List<ScanResult> scans) async {
    throw Exception('USB not yet supported.');
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
