import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanairz/models/scan_result.dart';

class PcConnector {
  Socket? _socket;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool get isConnected => _socket != null;

  Future<bool> connect(String ipAddress, int port) async {
    if (isConnected) return true;
    try {
      _socket = await Socket.connect(ipAddress, port,
          timeout: const Duration(seconds: 5));
      _connectionStatusController.add(true);
      _socket!.listen(
        (data) {
          // Handle incoming data from server if needed
        },
        onDone: () {
          disconnect();
        },
        onError: (error) {
          disconnect();
        },
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      print('Connection failed: $e');
      _socket = null;
      return false;
    }
  }

  void disconnect() {
    if (isConnected) {
      _socket?.destroy();
      _socket = null;
      _connectionStatusController.add(false);
    }
  }

  Future<void> syncData(List<ScanResult> scans) async {
    if (isConnected) {
      for (var scan in scans) {
        _socket?.writeln(scan.barcode);
      }
      await _socket?.flush();
    } else {
      throw Exception('Not connected to PC server.');
    }
  }

  void dispose() {
    _connectionStatusController.close();
    disconnect();
  }
}

final pcConnectorProvider = Provider<PcConnector>((ref) {
  final connector = PcConnector();
  ref.onDispose(() => connector.dispose());
  return connector;
});
