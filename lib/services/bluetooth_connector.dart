import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scanairz/models/scan_result.dart';

class BluetoothConnector {
  BluetoothConnection? _connection;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _connection != null && _connection!.isConnected;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    if (isConnected) return true;
    try {
      _connection = await BluetoothConnection.toAddress(macAddress);
      _connectionStatusController.add(true);

      _connection!.input?.listen((Uint8List data) {
        // Handle incoming data if needed
      }).onDone(() {
        _onDisconnected();
      });

      return true;
    } catch (e) {
      _connection = null;
      _connectionStatusController.add(false);
      return false;
    }
  }

  void _onDisconnected() {
    _connection = null;
    _connectionStatusController.add(false);
  }

  void disconnect() {
    _connection?.dispose();
    _onDisconnected();
  }

  Future<void> syncData(List<ScanResult> scans) async {
    if (!isConnected) throw Exception('Bluetooth not connected');
    try {
      for (final scan in scans) {
        final data = jsonEncode({'barcode': scan.barcode}) + '\n';
        _connection!.output.add(Uint8List.fromList(utf8.encode(data)));
        await _connection!.output.allSent;
      }
    } catch (e) {
      disconnect();
      rethrow;
    }
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}
