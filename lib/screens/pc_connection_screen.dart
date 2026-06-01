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
      _addLog(connected
          ? '✅ Connected to PC'
          : '🔴 Disconnected');
    });
  }

  void _addLog(String msg) {
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() => _log.insert(0, '[$time] $msg'));
    if (_log.length > 50) _log.removeLast();
  }

  Future<void> _findPc() async {
    if (_isDiscovering) return;
    setState(() { _isDiscovering = true; });
    _addLog('Searching for PC Companion on network…');

    await _discoverySub?.cancel();
    bool found = false;

    _discoverySub = _discovery.discoveredDevices.listen((devices) {
      if (!mounted || found) return;
      if (devices.isNotEmpty) {
        found = true;
        final device = devices.first;
        final parts = device.split(':');
        if (mounted) {
          setState(() {
            _ipController.text = parts[0];
            if (parts.length > 1) _portController.text = parts[1];
            _isDiscovering = false;
          });
          _addLog('Found PC at ${parts[0]}!');
        }
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
    if (!ok) _addLog('❌ WiFi connection failed.');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Connection'),
        bottom: TabBar(
          controller: _tabController,
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
          _buildActivityLog(),
        ],
      ),
    );
  }

  Widget _buildWifiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isConnected ? null : _findPc,
                    icon: _isDiscovering ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                    label: Text(_isDiscovering ? 'Searching...' : 'Auto-Discover PC'),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _ipController, decoration: const InputDecoration(labelText: 'PC IP Address')),
                  TextField(controller: _portController, decoration: const InputDecoration(labelText: 'Port')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isBusy ? null : (_isConnected ? () => _pcConnector.disconnect() : _connect),
                    style: ElevatedButton.styleFrom(backgroundColor: _isConnected ? Colors.red : Colors.blue, foregroundColor: Colors.white),
                    child: Text(_isConnected ? 'Disconnect' : 'Connect via WiFi'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isConnected ? _sync : null,
            icon: const Icon(Icons.sync),
            label: const Text('Sync Pending Scans'),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('Connect via Bluetooth Serial', style: TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(24),
            child: Text('Pair your phone with your PC in Windows settings, then select the PC from the Bluetooth device list.', textAlign: TextAlign.center),
          ),
          ElevatedButton(onPressed: null, child: Text('Select Paired Device')),
        ],
      ),
    );
  }

  Widget _buildUsbTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.usb, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text('Connect via USB Cable', style: TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(24),
            child: Text('Ensure USB Debugging or File Transfer mode is enabled on your phone.', textAlign: TextAlign.center),
          ),
          ElevatedButton(onPressed: null, child: Text('Detect USB Connection')),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Log', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(_log[i], style: const TextStyle(fontSize: 12)),
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
      color: isConnected ? Colors.green : Colors.grey,
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isConnected ? Icons.check_circle : Icons.error, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(isConnected ? 'Connected' : 'Not Connected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
