import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scanairz/models/scan_result.dart';

class BluetoothConnector {
  BluetoothConnection? _connection;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  bool get isConnected =>
      _connection != null && (_connection?.isConnected ?? false);

  /// Fetch a list of already-paired Bluetooth devices.
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      _devicesController.add(devices);
      return devices;
    } catch (e) {
      debugPrint('BluetoothConnector: getPairedDevices error: $e');
      return [];
    }
  }

  /// Connect to a specific paired device by its MAC address.
  Future<bool> connect(String macAddress) async {
    if (isConnected) return true;
    try {
      _connection = await BluetoothConnection.toAddress(macAddress);
      _connectionStatusController.add(true);

      // Listen for disconnection events
      _connection!.input!.listen(
        (_) {}, // incoming data – ignored for now
        onDone: () {
          disconnect();
        },
        onError: (_) {
          disconnect();
        },
        cancelOnError: true,
      );
      debugPrint('BluetoothConnector: Connected to $macAddress');
      return true;
    } catch (e) {
      debugPrint('BluetoothConnector: connect error: $e');
      _connection = null;
      return false;
    }
  }

  void disconnect() {
    if (isConnected) {
      _connection?.dispose();
      _connection = null;
      _connectionStatusController.add(false);
      debugPrint('BluetoothConnector: Disconnected');
    }
  }

  /// Send a list of scan results to the connected Bluetooth device.
  Future<void> syncData(List<ScanResult> scans) async {
    if (!isConnected) throw Exception('Bluetooth not connected.');
    for (final scan in scans) {
      final line = '${jsonEncode(scan.toJson())}\n';
      _connection!.output.add(Uint8List.fromList(utf8.encode(line)));
    }
    await _connection!.output.allSent;
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _devicesController.close();
  }
}
