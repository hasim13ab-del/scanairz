import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/services/network_discovery_service.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';

class PcConnectionScreen extends StatefulWidget {
  const PcConnectionScreen({super.key});

  @override
  State<PcConnectionScreen> createState() => _PcConnectionScreenState();
}

class _PcConnectionScreenState extends State<PcConnectionScreen> with SingleTickerProviderStateMixin {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8765');

  late PcConnector _pcConnector;
  late SettingsService _settingsService;
  late StorageService _storageService;
  late TabController _tabController;

  StreamSubscription<bool>? _connSub;
  bool _isConnected = false;
  bool _isBusy = false;
  bool _isDiscovering = false;
  final List<String> _log = [];

  final NetworkDiscoveryService _discovery = NetworkDiscoveryService();
  StreamSubscription<List<String>>? _discoverySub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pcConnector = Provider.of<PcConnector>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _isConnected = _pcConnector.isConnected;
    _connSub ??= _pcConnector.connectionStatus.listen(_onConnectionChanged);
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final s = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _ipController.text = s['ipAddress'] ?? '';
      _portController.text = s['port'] ?? '8765';
    });
  }

  void _onConnectionChanged(bool connected) {
    if (!mounted) return;
    setState(() {
      _isConnected = connected;
      _addLog(connected ? '✅ Connected to PC' : '🔴 Disconnected');
    });
  }

  void _addLog(String msg) {
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (mounted) setState(() => _log.insert(0, '[$time] $msg'));
    if (_log.length > 50) _log.removeLast();
  }

  Future<void> _findPc() async {
    if (_isDiscovering) return;
    setState(() { _isDiscovering = true; });
    _addLog('Searching for PC on network…');

    await _discoverySub?.cancel();
    bool found = false;

    _discoverySub = _discovery.discoveredDevices.listen((devices) {
      if (!mounted || found) return;
      if (devices.isNotEmpty) {
        found = true;
        final device = devices.first;
        final parts = device.split(':');
        setState(() {
          _ipController.text = parts[0];
          if (parts.length > 1) _portController.text = parts[1];
          _isDiscovering = false;
        });
        _addLog('Found PC at ${parts[0]}!');
        _discovery.stopDiscovery();
      }
    });

    _discovery.startDiscovery();
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_isDiscovering && !found) {
        _discovery.stopDiscovery();
        setState(() => _isDiscovering = false);
        _addLog('PC not found on WiFi.');
      }
    });
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (ip.isEmpty || port == null) return;
    setState(() { _isBusy = true; });
    final ok = await _pcConnector.connectWifi(ip, port);
    setState(() => _isBusy = false);
    if (!ok) _addLog('❌ Connection failed.');
  }

  Future<void> _sync() async {
    if (!_isConnected) return;
    final scans = await _storageService.loadScanResults();
    if (scans.isEmpty) { _addLog('No scans to sync.'); return; }
    setState(() => _isBusy = true);
    try {
      await _pcConnector.syncData(scans);
      await _storageService.clearScanResults();
      _addLog('✅ Sync complete! Sent ${scans.length} scans.');
    } catch (e) {
      _addLog('Sync failed: $e');
    }
    setState(() => _isBusy = false);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _discoverySub?.cancel();
    _discovery.dispose();
    _ipController.dispose();
    _portController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to PC'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'WiFi', icon: Icon(Icons.wifi)),
            Tab(text: 'Bluetooth', icon: Icon(Icons.bluetooth)),
            Tab(text: 'USB', icon: Icon(Icons.usb)),
          ],
        ),
      ),
      body: Column(
        children: [
          _StatusBanner(isConnected: _isConnected, isBusy: _isBusy),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWifiTab(),
                _buildBluetoothTab(),
                _buildUsbTab(),
              ],
            ),
          ),
          _buildActivityLog(isDark),
        ],
      ),
    );
  }

  Widget _buildWifiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isConnected ? null : _findPc,
                    icon: _isDiscovering ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                    label: Text(_isDiscovering ? 'Searching...' : 'Auto-Discover PC'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(labelText: 'PC IP Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.computer)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder(), prefixIcon: Icon(Icons.settings_input_component)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isBusy ? null : (_isConnected ? () => _pcConnector.disconnect() : _connect),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.red : const Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isConnected ? 'Disconnect' : 'Connect via WiFi', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isConnected ? _sync : null,
            icon: const Icon(Icons.sync),
            label: const Text('Sync Pending Scans'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: const Color(0xFF1A2744), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('Bluetooth Connectivity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Pair your phone with your Windows PC first. Then select the PC from the list of paired devices to start syncing.', 
                       textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: null, // Stub for now
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Scan for Paired PC'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsbTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.usb, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text('USB Connectivity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Connect your phone via USB cable and ensure "USB Debugging" or "File Transfer" is enabled.', 
                       textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: null, // Stub for now
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(200, 50)),
              child: const Text('Detect Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog(bool isDark) {
    return Container(
      height: 140,
      width: double.infinity,
      color: isDark ? Colors.black26 : Colors.grey.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('LOG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                const Spacer(),
                if (_log.isNotEmpty) GestureDetector(onTap: () => setState(() => _log.clear()), child: const Icon(Icons.clear_all, size: 16, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _log.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(_log[i], style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool isBusy;
  const _StatusBanner({required this.isConnected, required this.isBusy});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: isConnected ? Colors.green : Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isConnected ? Icons.check_circle : Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(isConnected ? 'CONNECTED TO PC' : 'NOT CONNECTED', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          if (isBusy) ...[
            const Spacer(),
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ]
        ],
      ),
    );
  }
}
