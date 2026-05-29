import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

const int defaultScanPort = 8765;
const int discoveryPort = 8888;
const int vkControl = 0x11;
const int vkV = 0x56;
const int vkReturn = 0x0D;
const int keyEventKeyUp = 0x0002;
bool typeIntoActiveApp = true;

typedef KeybdEventNative = Void Function(
  Uint8 bVk,
  Uint8 bScan,
  Uint32 dwFlags,
  IntPtr dwExtraInfo,
);
typedef KeybdEventDart = void Function(
  int bVk,
  int bScan,
  int dwFlags,
  int dwExtraInfo,
);

final KeybdEventDart _keybdEvent = DynamicLibrary.open('user32.dll')
    .lookupFunction<KeybdEventNative, KeybdEventDart>('keybd_event');

Future<void> main(List<String> args) async {
  final port = _readPort(args);
  typeIntoActiveApp = !args.contains('--no-type');
  final addresses = await _localIPv4Addresses();

  stdout.writeln('ScanAiRZ PC Companion');
  stdout.writeln('Listening for scans on TCP port $port');
  stdout.writeln('Discovery responder on UDP port $discoveryPort');
  if (addresses.isNotEmpty) {
    stdout.writeln('Use one of these PC IP addresses in the phone app:');
    for (final address in addresses) {
      stdout.writeln('  - $address');
    }
  }
  stdout.writeln('');
  if (typeIntoActiveApp) {
    stdout.writeln('Focus the target field on this PC, then scan from the phone.');
  } else {
    stdout.writeln('Test mode: scans will be logged but not typed.');
  }
  stdout.writeln('Press Ctrl+C to stop.');
  stdout.writeln('');

  await _startDiscoveryResponder(port);
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);

  await for (final socket in server) {
    unawaited(_handleClient(socket));
  }
}

int _readPort(List<String> args) {
  if (args.isEmpty) {
    return defaultScanPort;
  }

  final port = int.tryParse(args.first);
  if (port == null || port < 1 || port > 65535) {
    stderr.writeln('Invalid port "${args.first}". Using $defaultScanPort.');
    return defaultScanPort;
  }

  return port;
}

Future<List<String>> _localIPv4Addresses() async {
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  return interfaces
      .expand((interface) => interface.addresses)
      .map((address) => address.address)
      .toList()
    ..sort();
}

Future<void> _startDiscoveryResponder(int port) async {
  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    discoveryPort,
  );

  socket.listen((event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final datagram = socket.receive();
    if (datagram == null) {
      return;
    }

    final message = utf8.decode(datagram.data, allowMalformed: true);
    if (message.trim() != 'scanairz_discovery') {
      return;
    }

    final response = utf8.encode(jsonEncode({
      'app': 'scanairz_pc',
      'port': port,
    }));
    socket.send(response, datagram.address, datagram.port);
  });
}

Future<void> _handleClient(Socket socket) async {
  final remote = '${socket.remoteAddress.address}:${socket.remotePort}';
  stdout.writeln('Connected: $remote');

  try {
    await for (final line
        in utf8.decoder.bind(socket).transform(const LineSplitter())) {
      final barcode = _extractBarcode(line);
      if (barcode == null || barcode.isEmpty) {
        continue;
      }

      if (typeIntoActiveApp) {
        await _sendToActiveApp(barcode);
      }
      stdout.writeln('${DateTime.now().toLocal()}  $barcode');
    }
  } catch (error) {
    stderr.writeln('Connection error from $remote: $error');
  } finally {
    await socket.close();
    stdout.writeln('Disconnected: $remote');
  }
}

String? _extractBarcode(String line) {
  try {
    final decoded = jsonDecode(line);
    if (decoded is Map) {
      return decoded['barcode']?.toString();
    }
  } catch (_) {
    return line.trim();
  }

  return line.trim();
}

Future<void> _sendToActiveApp(String barcode) async {
  await _setClipboard(barcode);
  _pressCtrlV();
  _pressKey(vkReturn);
}

Future<void> _setClipboard(String text) async {
  final process = await Process.start(
    'powershell.exe',
    [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      r'$input | Set-Clipboard',
    ],
  );
  process.stdin.write(text);
  await process.stdin.close();
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw StateError('Unable to write scan to clipboard.');
  }
}

void _pressCtrlV() {
  _keybdEvent(vkControl, 0, 0, 0);
  _keybdEvent(vkV, 0, 0, 0);
  _keybdEvent(vkV, 0, keyEventKeyUp, 0);
  _keybdEvent(vkControl, 0, keyEventKeyUp, 0);
}

void _pressKey(int key) {
  _keybdEvent(key, 0, 0, 0);
  _keybdEvent(key, 0, keyEventKeyUp, 0);
}
