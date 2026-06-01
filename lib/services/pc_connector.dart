import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/services/bluetooth_connector.dart';
import 'package:scanairz/services/usb_connector.dart';

enum ConnectionType { wifi, bluetooth, usb }

class PcConnector {
  // ── WiFi ──────────────────────────────────────────────────────────────────
  Socket? _socket;

  // ── Bluetooth ─────────────────────────────────────────────────────────────
  final BluetoothConnector _btConnector = BluetoothConnector();

  // ── USB ───────────────────────────────────────────────────────────────────
  final UsbConnector _usbConnector = UsbConnector();

  // ── Unified status ────────────────────────────────────────────────────────
  ConnectionType _activeType = ConnectionType.wifi;
  ConnectionType get activeType => _activeType;

  String? _lastIp;
  int? _lastPort;
  Timer? _reconnectTimer;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _statusController.stream;

  bool get isConnected {
    switch (_activeType) {
      case ConnectionType.wifi:
        return _socket != null;
      case ConnectionType.bluetooth:
        return _btConnector.isConnected;
      case ConnectionType.usb:
        return _usbConnector.isConnected;
    }
  }

  // ── WiFi connection ───────────────────────────────────────────────────────
  Future<bool> connectWifi(String ipAddress, int port) async {
    _activeType = ConnectionType.wifi;
    _lastIp = ipAddress;
    _lastPort = port;
    if (_socket != null) return true;
    try {
      _socket = await Socket.connect(ipAddress, port,
          timeout: const Duration(seconds: 5));
      _statusController.add(true);
      _reconnectTimer?.cancel();
      _socket!.listen(
        (_) {},
        onDone: () => _onWifiDone(),
        onError: (_) => _onWifiDone(),
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      debugPrint('PcConnector WiFi: $e');
      _socket = null;
      return false;
    }
  }

  void _onWifiDone() {
    _socket = null;
    _statusController.add(false);
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    if (_lastIp == null || _lastPort == null) return;
    
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (isConnected) {
        timer.cancel();
        return;
      }
      debugPrint('PcConnector: Attempting auto-reconnect to $_lastIp:$_lastPort...');
      await connectWifi(_lastIp!, _lastPort!);
    });
  }

  // ── Bluetooth connection ──────────────────────────────────────────────────
  Future<List<BluetoothDevice>> getBluetoothDevices() async {
    final devices = await _btConnector.getPairedDevices();
    return devices.cast<BluetoothDevice>();
  }

  Future<bool> connectBluetooth(String macAddress) async {
    _activeType = ConnectionType.bluetooth;
    final ok = await _btConnector.connect(macAddress);
    _statusController.add(ok);
    // Forward subsequent BT status changes
    _btConnector.connectionStatus.listen((s) => _statusController.add(s));
    return ok;
  }

  // ── USB connection ────────────────────────────────────────────────────────
  Future<List<UsbDevice>> getUsbDevices() async {
    final devices = await _usbConnector.getDevices();
    return devices.cast<UsbDevice>();
  }

  Future<bool> connectUsb(UsbDevice device) async {
    _activeType = ConnectionType.usb;
    final ok = await _usbConnector.connect(device);
    _statusController.add(ok);
    _usbConnector.connectionStatus.listen((s) => _statusController.add(s));
    return ok;
  }

  // ── Disconnect (any) ──────────────────────────────────────────────────────
  void disconnect() {
    _reconnectTimer?.cancel();
    _lastIp = null;
    _lastPort = null;
    switch (_activeType) {
      case ConnectionType.wifi:
        _socket?.destroy();
        _socket = null;
        break;
      case ConnectionType.bluetooth:
        _btConnector.disconnect();
        break;
      case ConnectionType.usb:
        _usbConnector.disconnect();
        break;
    }
    _statusController.add(false);
  }

  // ── Sync data (any connection) ────────────────────────────────────────────
  Future<void> syncData(List<ScanResult> scans) async {
    if (!isConnected) throw Exception('Not connected.');
    switch (_activeType) {
      case ConnectionType.wifi:
        for (final scan in scans) {
          _socket!.writeln(jsonEncode({'barcode': scan.barcode}));
        }
        await _socket!.flush();
        break;
      case ConnectionType.bluetooth:
        await _btConnector.syncData(scans);
        break;
      case ConnectionType.usb:
        await _usbConnector.syncData(scans);
        break;
    }
  }

  void dispose() {
    disconnect();
    _btConnector.dispose();
    _usbConnector.dispose();
    _statusController.close();
  }
}
