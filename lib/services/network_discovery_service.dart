
import 'dart:async';
import 'dart:io';

class NetworkDiscoveryService {
  bool _isDiscovering = false;
  RawDatagramSocket? _socket;
  final StreamController<List<String>> _discoveredDevicesController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get discoveredDevices =>
      _discoveredDevicesController.stream;

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    _isDiscovering = true;
    final List<String> discoveredDevices = [];
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          final address = datagram.address.address;
          if (!discoveredDevices.contains(address)) {
            discoveredDevices.add(address);
            _discoveredDevicesController.add(discoveredDevices);
          }
        }
      }
    });

    // Broadcast a discovery message every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDiscovering) {
        timer.cancel();
        return;
      }
      _broadcastDiscoveryMessage();
    });
  }

  void stopDiscovery() {
    _isDiscovering = false;
    _socket?.close();
    _socket = null;
  }

  void _broadcastDiscoveryMessage() {
    const discoveryMessage = 'scanairz_discovery';
    final data = discoveryMessage.codeUnits;
    _socket?.send(data, InternetAddress('255.255.255.255'), 8888);
  }

  void dispose() {
    stopDiscovery();
    _discoveredDevicesController.close();
  }
}
