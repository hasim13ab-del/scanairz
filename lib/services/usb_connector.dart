import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:scanairz/models/scan_result.dart';

class UsbConnector {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _inputSubscription;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<List<UsbDevice>> _devicesController =
      StreamController<List<UsbDevice>>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<List<UsbDevice>> get devicesStream => _devicesController.stream;

  bool get isConnected => _port != null;

  /// Get a list of currently connected USB serial devices.
  Future<List<UsbDevice>> getDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      _devicesController.add(devices);
      return devices;
    } catch (e) {
      debugPrint('UsbConnector: getDevices error: $e');
      return [];
    }
  }

  /// Connect to a USB device and open a serial port at 9600 baud.
  Future<bool> connect(UsbDevice device) async {
    if (isConnected) return true;
    try {
      _port = await device.create();
      if (_port == null) return false;

      final opened = await _port!.open();
      if (!opened) {
        _port = null;
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _inputSubscription = _port!.inputStream?.listen(
        (_) {}, // incoming data – ignored for now
        onDone: () => disconnect(),
        onError: (_) => disconnect(),
        cancelOnError: true,
      );

      _connectionStatusController.add(true);
      debugPrint('UsbConnector: Connected to ${device.productName}');
      return true;
    } catch (e) {
      debugPrint('UsbConnector: connect error: $e');
      _port = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_port != null) {
      await _inputSubscription?.cancel();
      _inputSubscription = null;
      await _port!.close();
      _port = null;
      _connectionStatusController.add(false);
      debugPrint('UsbConnector: Disconnected');
    }
  }

  /// Send scan results over the USB serial connection.
  Future<void> syncData(List<ScanResult> scans) async {
    if (!isConnected) throw Exception('USB not connected.');
    for (final scan in scans) {
      final line = '${jsonEncode(scan.toJson())}\n';
      await _port!.write(Uint8List.fromList(utf8.encode(line)));
    }
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _devicesController.close();
  }
}
