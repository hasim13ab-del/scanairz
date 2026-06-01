import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:scanairz/models/scan_result.dart';

class UsbConnector {
  UsbPort? _port;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _port != null;

  Future<List<UsbDevice>> getDevices() async {
    return await UsbSerial.listDevices();
  }

  Future<bool> connect(UsbDevice device) async {
    if (isConnected) return true;
    try {
      _port = await device.create();
      if (_port == null) return false;

      bool openResult = await _port!.open();
      if (!openResult) {
        _port = null;
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      _port!.setPortParameters(9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      _connectionStatusController.add(true);
      
      _port!.inputStream?.listen((Uint8List data) {
         // Incoming USB data
      });

      return true;
    } catch (e) {
      _port = null;
      _connectionStatusController.add(false);
      return false;
    }
  }

  Future<void> disconnect() async {
    await _port?.close();
    _port = null;
    _connectionStatusController.add(false);
  }

  Future<void> syncData(List<ScanResult> scans) async {
    if (!isConnected) throw Exception('USB not connected');
    try {
      for (final scan in scans) {
        final data = jsonEncode({'barcode': scan.barcode}) + '\n';
        _port!.write(Uint8List.fromList(utf8.encode(data)));
      }
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}
