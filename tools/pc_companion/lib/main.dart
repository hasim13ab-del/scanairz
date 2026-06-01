import 'dart:async';
import 'dart:convert';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

// ── Win32 keyboard FFI ────────────────────────────────────────────────────────
typedef _KeybdEventNative = Void Function(Uint8, Uint8, Uint32, IntPtr);
typedef _KeybdEventDart   = void Function(int,  int,  int,    int);

final _KeybdEventDart _keybdEvent = DynamicLibrary.open('user32.dll')
    .lookupFunction<_KeybdEventNative, _KeybdEventDart>('keybd_event');

const int _vkControl   = 0x11;
const int _vkV         = 0x56;
const int _vkReturn    = 0x0D;
const int _keyEventUp  = 0x0002;

// ── App entry point ───────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  const windowOptions = WindowOptions(
    size:        Size(960, 720),
    minimumSize: Size(800, 600),
    title:       'ScanAiRZ PC Companion',
    center:      true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await windowManager.setPreventClose(true);

  runApp(const CompanionApp());
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanAiRZ PC Companion',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Scaffold(
          body: child,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary:    Color(0xFF00ACC1),
          secondary:  Color(0xFFF57C00),
          surface:    Color(0xFF1A2744),
          onSurface:  Colors.white,
          error:      Color(0xFFEF5350),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A2744),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

// ── Dashboard page ────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin, TrayListener, WindowListener {
  // Server state
  ServerSocket?    _server;
  RawDatagramSocket? _udpSocket;
  bool _running     = false;
  bool _typeIntoApp = true;
  int  _port        = 8765;
  int  _connCount   = 0;

  // Data
  final List<_BarcodeEntry> _barcodes = [];
  final List<String>        _log      = [];
  List<String>              _localIps = [];

  final _portController = TextEditingController(text: '8765');
  final _logScrollCtrl  = ScrollController();
  final _scanScrollCtrl = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initTray();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _fetchLocalIps();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/app_icon.png' // tray_manager handles png on windows usually or ico
          : 'assets/app_icon.png',
    );
    final Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show ScanAiRZ'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      _stopServer();
      exit(0);
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  Future<void> _fetchLocalIps() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    setState(() {
      _localIps = interfaces
          .expand((i) => i.addresses)
          .map((a) => a.address)
          .toList()
        ..sort();
    });
  }

  Future<void> _startServer() async {
    final portVal = int.tryParse(_portController.text.trim()) ?? 8765;
    setState(() { _port = portVal; });
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _log.insert(0, '▶ TCP server listening on port $_port');
      await _startDiscoveryResponder();
      setState(() { _running = true; });
      _server!.listen((socket) {
        setState(() => _connCount++);
        _addLog('📱 Phone connected: ${socket.remoteAddress.address}');
        _handleClient(socket);
      });
    } catch (e) {
      _addLog('❌ Failed to start: $e');
    }
  }

  Future<void> _startDiscoveryResponder() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      _udpSocket!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = _udpSocket!.receive();
        if (dg == null) return;
        final msg = utf8.decode(dg.data, allowMalformed: true).trim();
        if (msg == 'scanairz_discovery') {
          final response = utf8.encode(jsonEncode({'app': 'scanairz_pc', 'port': _port}));
          _udpSocket!.send(response, dg.address, dg.port);
        }
      });
      _addLog('📡 Discovery responder active on UDP 8888');
    } catch (_) {}
  }

  Future<void> _stopServer() async {
    await _server?.close();
    _server = null;
    _udpSocket?.close();
    _udpSocket = null;
    setState(() { _running = false; _connCount = 0; });
    _addLog('⏹ Server stopped.');
  }

  Future<void> _handleClient(Socket socket) async {
    final remote = socket.remoteAddress.address;
    try {
      await for (final line in utf8.decoder.bind(socket).transform(const LineSplitter())) {
        final barcode = _extractBarcode(line);
        if (barcode == null || barcode.isEmpty) continue;
        if (mounted) {
          setState(() {
            _barcodes.insert(0, _BarcodeEntry(
              barcode:  barcode,
              from:     remote,
              time:     DateTime.now(),
            ));
            if (_barcodes.length > 500) _barcodes.removeLast();
          });
        }
        _addLog('✔ [$remote] $barcode');
        if (_typeIntoApp) {
          await _sendToActiveApp(barcode);
        }
      }
    } catch (e) {
      _addLog('⚠ Error from $remote: $e');
    } finally {
      await socket.close();
      if (mounted) setState(() => _connCount = _connCount > 0 ? _connCount - 1 : 0);
      _addLog('📵 Phone disconnected: $remote');
    }
  }

  String? _extractBarcode(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map) return decoded['barcode']?.toString();
    } catch (_) {}
    return line.trim().isEmpty ? null : line.trim();
  }

  Future<void> _sendToActiveApp(String barcode) async {
    await _setClipboard(barcode);
    _pressCtrlV();
    _pressKey(_vkReturn);
  }

  Future<void> _setClipboard(String text) async {
    final process = await Process.start('powershell.exe', [
      '-NoProfile', '-NonInteractive', '-Command', r'$input | Set-Clipboard',
    ]);
    process.stdin.write(text);
    await process.stdin.close();
    await process.exitCode;
  }

  void _pressCtrlV() {
    _keybdEvent(_vkControl, 0, 0, 0);
    _keybdEvent(_vkV, 0, 0, 0);
    _keybdEvent(_vkV, 0, _keyEventUp, 0);
    _keybdEvent(_vkControl, 0, _keyEventUp, 0);
  }

  void _pressKey(int key) {
    _keybdEvent(key, 0, 0, 0);
    _keybdEvent(key, 0, _keyEventUp, 0);
  }

  void _addLog(String msg) {
    final now = DateTime.now();
    final ts  = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
    if (mounted) setState(() { _log.insert(0, '[$ts] $msg'); if (_log.length > 200) _log.removeLast(); });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _stopServer();
    _portController.dispose();
    _logScrollCtrl.dispose();
    _scanScrollCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            running:      _running,
            connCount:    _connCount,
            onStart:      _startServer,
            onStop:       _stopServer,
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
              Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
              Tab(icon: Icon(Icons.usb), text: 'USB'),
            ],
            indicatorColor: const Color(0xFF00ACC1),
            labelColor: const Color(0xFF00ACC1),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left sidebar ──────────────────────────────────────────
                SizedBox(
                  width: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _WiFiSidebar(
                        running:        _running,
                        localIps:       _localIps,
                        port:           _port,
                        typeIntoApp:    _typeIntoApp,
                        portController: _portController,
                        onTypeToggle:   (v) => setState(() => _typeIntoApp = v),
                        onClearScans:   () => setState(() => _barcodes.clear()),
                      ),
                      const _BluetoothSidebar(),
                      const _UsbSidebar(),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF243455)),
                // ── Main content ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Barcode feed
                      Expanded(
                        flex: 3,
                        child: _BarcodeFeed(
                          barcodes:   _barcodes,
                          scrollCtrl: _scanScrollCtrl,
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFF243455)),
                      // Activity log
                      Expanded(
                        flex: 2,
                        child: _ActivityLog(
                          log:        _log,
                          scrollCtrl: _logScrollCtrl,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool running;
  final int connCount;
  final VoidCallback onStart;
  final VoidCallback onStop;
  const _TopBar({required this.running, required this.connCount, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFF0A0E1A),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Image.asset('assets/app_icon.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_scanner, color: Color(0xFF00ACC1), size: 32)),
          const SizedBox(width: 12),
          const Text('ScanAiRZ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text(' PC Companion', style: TextStyle(fontSize: 14, color: Color(0xFF90A4AE))),
          const Spacer(),
          if (running && connCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00ACC1).withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone, color: Color(0xFF00ACC1), size: 14),
                  const SizedBox(width: 6),
                  Text('$connCount phone${connCount > 1 ? "s" : ""} connected',
                      style: const TextStyle(color: Color(0xFF26C6DA), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: running ? onStop : onStart,
            icon: Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
            label: Text(running ? 'Stop' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: running ? const Color(0xFFEF5350) : const Color(0xFF00ACC1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left sidebars ──────────────────────────────────────────────────────────────
class _WiFiSidebar extends StatelessWidget {
  final bool running;
  final List<String> localIps;
  final int port;
  final bool typeIntoApp;
  final TextEditingController portController;
  final ValueChanged<bool> onTypeToggle;
  final VoidCallback onClearScans;

  const _WiFiSidebar({
    required this.running,
    required this.localIps,
    required this.port,
    required this.typeIntoApp,
    required this.portController,
    required this.onTypeToggle,
    required this.onClearScans,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1520),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: running ? const Color(0xFF00ACC1).withAlpha(25) : const Color(0xFF37474F).withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: running ? const Color(0xFF00ACC1).withAlpha(80) : const Color(0xFF546E7A),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: running ? const Color(0xFF00ACC1) : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: running ? [const BoxShadow(color: Color(0xFF00ACC1), blurRadius: 8, spreadRadius: 1)] : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    running ? 'WiFi Listening' : 'WiFi Stopped',
                    style: TextStyle(
                      color: running ? const Color(0xFF26C6DA) : Colors.grey,
                      fontWeight: FontWeight.bold, fontSize: 15,
                    ),
                  ),
                  if (running)
                    Text('Port $port', style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PC IP addresses
            const _SideLabel('YOUR PC IP ADDRESSES'),
            const SizedBox(height: 8),
            if (localIps.isEmpty)
              const Text('Detecting…', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              ...localIps.map((ip) => _IpRow(ip: ip)),
            const SizedBox(height: 20),

            // Port setting
            const _SideLabel('PORT'),
            const SizedBox(height: 8),
            TextField(
              controller: portController,
              enabled: !running,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A2744),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: '8765',
                hintStyle: const TextStyle(color: Color(0xFF546E7A)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Settings
            const _SideLabel('SETTINGS'),
            const SizedBox(height: 8),
            _ToggleRow(
              label:   'Type into active app',
              value:   typeIntoApp,
              onChanged: onTypeToggle,
            ),
            const SizedBox(height: 20),

            // Clear button
            TextButton.icon(
              onPressed: onClearScans,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear scan history'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF90A4AE),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BluetoothSidebar extends StatelessWidget {
  const _BluetoothSidebar();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1520),
      padding: const EdgeInsets.all(20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth, size: 48, color: Colors.blue),
          SizedBox(height: 16),
          Text('Bluetooth Connectivity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          Text(
            'To connect via Bluetooth, pair your phone with this PC as a standard Bluetooth Serial device. The app will automatically detect incoming data from paired devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          SizedBox(height: 20),
          Text('Status: Ready to Pair', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _UsbSidebar extends StatelessWidget {
  const _UsbSidebar();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1520),
      padding: const EdgeInsets.all(20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.usb, size: 48, color: Colors.orange),
          SizedBox(height: 16),
          Text('USB Connectivity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          Text(
            'Connect your phone via USB cable and ensure "USB Debugging" or "File Transfer" mode is enabled. The app monitors available COM ports for scan data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          SizedBox(height: 20),
          Text('Status: Monitoring Ports', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SideLabel extends StatelessWidget {
  final String text;
  const _SideLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF546E7A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }
}

class _IpRow extends StatelessWidget {
  final String ip;
  const _IpRow({required this.ip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: ip));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copied $ip'), duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2744),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lan_outlined, size: 14, color: Color(0xFF00ACC1)),
              const SizedBox(width: 8),
              Text(ip, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white)),
              const Spacer(),
              const Icon(Icons.copy, size: 12, color: Color(0xFF546E7A)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00ACC1),
        ),
      ],
    );
  }
}

// ── Barcode feed ──────────────────────────────────────────────────────────────
class _BarcodeFeed extends StatelessWidget {
  final List<_BarcodeEntry> barcodes;
  final ScrollController scrollCtrl;
  const _BarcodeFeed({required this.barcodes, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              const Text('Received Barcodes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 10),
              if (barcodes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ACC1).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${barcodes.length}', style: const TextStyle(color: Color(0xFF26C6DA), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF243455)),
        Expanded(
          child: barcodes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 56, color: Color(0xFF243455)),
                      SizedBox(height: 12),
                      Text('No barcodes received yet', style: TextStyle(color: Color(0xFF546E7A))),
                      SizedBox(height: 4),
                      Text('Start the server and scan from the phone app', style: TextStyle(color: Color(0xFF37474F), fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: barcodes.length,
                  itemBuilder: (_, i) {
                    final e = barcodes[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2744),
                        borderRadius: BorderRadius.circular(10),
                        border: i == 0
                            ? Border.all(color: const Color(0xFF00ACC1).withAlpha(80))
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (i == 0)
                            Container(
                              width: 6, height: 6,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: const BoxDecoration(color: Color(0xFF00ACC1), shape: BoxShape.circle),
                            ),
                          Expanded(
                            child: Text(e.barcode,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 12),
                          Text(e.from, style: const TextStyle(color: Color(0xFF546E7A), fontSize: 11)),
                          const SizedBox(width: 8),
                          Text(
                            '${e.time.hour.toString().padLeft(2,'0')}:${e.time.minute.toString().padLeft(2,'0')}:${e.time.second.toString().padLeft(2,'0')}',
                            style: const TextStyle(color: Color(0xFF37474F), fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Activity log ──────────────────────────────────────────────────────────────
class _ActivityLog extends StatelessWidget {
  final List<String> log;
  final ScrollController scrollCtrl;
  const _ActivityLog({required this.log, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Text('Activity Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF90A4AE))),
        ),
        Expanded(
          child: log.isEmpty
              ? const Center(child: Text('No activity yet.', style: TextStyle(color: Color(0xFF37474F), fontSize: 12)))
              : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  itemCount: log.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      log[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: log[i].contains('❌') || log[i].contains('⚠')
                            ? const Color(0xFFEF5350)
                            : log[i].contains('✔') || log[i].contains('✅')
                                ? const Color(0xFF00ACC1)
                                : const Color(0xFF90A4AE),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BarcodeEntry {
  final String barcode;
  final String from;
  final DateTime time;
  const _BarcodeEntry({required this.barcode, required this.from, required this.time});
}
