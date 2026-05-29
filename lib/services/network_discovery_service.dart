
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class NetworkDiscoveryService {
  bool _isDiscovering = false;
  RawDatagramSocket? _socket;
  Timer? _discoveryTimer;
  final StreamController<List<String>> _discoveredDevicesController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get discoveredDevices =>
      _discoveredDevicesController.stream;

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    _isDiscovering = true;
    final List<String> discoveredDevices = [];
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;
    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          final address = datagram.address.address;
          final device = _formatDiscoveredDevice(address, datagram.data);
          if (!discoveredDevices.contains(device)) {
            discoveredDevices.add(device);
            _discoveredDevicesController.add(discoveredDevices);
          }
        }
      }
    });

    // Broadcast a discovery message every 5 seconds
    _broadcastDiscoveryMessage();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDiscovering) {
        timer.cancel();
        return;
      }
      _broadcastDiscoveryMessage();
    });
  }

  void stopDiscovery() {
    _isDiscovering = false;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _socket?.close();
    _socket = null;
  }

  void _broadcastDiscoveryMessage() {
    const discoveryMessage = 'scanairz_discovery';
    final data = discoveryMessage.codeUnits;
    _socket?.send(data, InternetAddress('255.255.255.255'), 8888);
  }

  String _formatDiscoveredDevice(String address, List<int> data) {
    try {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map && decoded['app'] == 'scanairz_pc') {
        final port = decoded['port'];
        if (port is int) {
          return '$address:$port';
        }
      }
    } catch (_) {
      // Older companion responses may be plain packets; the sender IP is enough.
    }

    return address;
  }

  void dispose() {
    stopDiscovery();
    _discoveredDevicesController.close();
  }
}
