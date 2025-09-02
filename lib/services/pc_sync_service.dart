import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/scan_result.dart';

class PcSyncService {
  WebSocketChannel? _channel;
  final Connectivity _connectivity = Connectivity();

  Future<bool> connectToPC(String ipAddress) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ipAddress:8080'));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncData(List<ScanResult> results) async {
    if (_channel == null) return false;
    
    try {
      for (final result in results) {
        _channel!.sink.add(jsonEncode(result.toMap()));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> discoverPCs() async {
    // This would typically use network discovery protocols
    // For now, return a mock list
    return ['192.168.1.100', '192.168.1.101'];
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  Future<bool> checkConnectivity() async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }
}