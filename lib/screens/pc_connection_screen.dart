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

class _PcConnectionScreenState extends State<PcConnectionScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8765');

  late PcConnector _pcConnector;
  late SettingsService _settingsService;
  late StorageService _storageService;

  StreamSubscription<bool>? _connSub;
  bool _isConnected = false;
  bool _isBusy = false;
  bool _isDiscovering = false;
  final List<String> _log = [];

  final NetworkDiscoveryService _discovery = NetworkDiscoveryService();
  StreamSubscription<List<String>>? _discoverySub;

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
          ? '✅ Connected via WiFi'
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
    _addLog('Searching for ScanAiRZ PC Companion on your network…');

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
          _addLog('Found PC Companion at ${parts[0]}! IP filled in automatically.');
        }
        _discovery.stopDiscovery();
      }
    });

    _discovery.startDiscovery();

    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_isDiscovering && !found) {
        _discovery.stopDiscovery();
        setState(() => _isDiscovering = false);
        _addLog('PC Companion not found. Make sure it is running on the same WiFi network.');
      }
    });
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (ip.isEmpty || port == null) {
      _addLog('Enter a valid IP address and port.');
      return;
    }
    setState(() { _isBusy = true; });
    _addLog('Connecting to $ip:$port…');
    // Save IP for next session
    final existing = await _settingsService.loadSettings();
    await _settingsService.saveSettings(
      connectionMethod: existing['connectionMethod'] as String? ?? 'Wi-Fi',
      ipAddress: ip,
      port: port.toString(),
      continuousScan: existing['continuousScan'] as bool? ?? false,
      vibration: existing['vibration'] as bool? ?? true,
      laserAnimation: existing['laserAnimation'] as bool? ?? true,
      saveHistory: existing['saveHistory'] as bool? ?? true,
      autoClearHistoryDays: existing['autoClearHistoryDays'] as int? ?? 7,
      theme: existing['theme'] as String? ?? 'System',
    );
    final ok = await _pcConnector.connectWifi(ip, port);
    setState(() => _isBusy = false);
    if (!ok) _addLog('❌ Connection failed. Check IP and make sure PC Companion is running.');
  }

  Future<void> _sync() async {
    if (!_isConnected) { _addLog('Not connected.'); return; }
    final scans = await _storageService.loadScanResults();
    if (scans.isEmpty) { _addLog('No scans to sync.'); return; }
    setState(() => _isBusy = true);
    _addLog('Syncing ${scans.length} scan(s)…');
    try {
      await _pcConnector.syncData(scans);
      await _storageService.clearScanResults();
      _addLog('✅ Sync complete! ${scans.length} scan(s) sent to PC.');
    } catch (e) {
      _addLog('Sync failed: $e');
    }
    setState(() => _isBusy = false);
  }

  void _disconnect() {
    _pcConnector.disconnect();
    _addLog('Disconnected.');
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _discoverySub?.cancel();
    _discovery.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('PC Sync')),
      body: Column(
        children: [
          _StatusBanner(isConnected: _isConnected, isBusy: _isBusy),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // How-to card
                  if (!_isConnected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00ACC1).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00ACC1).withAlpha(60)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF00ACC1), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Run the ScanAiRZ PC Companion on your Windows PC first, '
                              'then tap "Find PC" or enter the IP shown on the PC app.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // WiFi connection card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wifi, color: Color(0xFF00ACC1), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'WiFi Connection',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Find PC button
                          OutlinedButton.icon(
                            onPressed: (_isConnected || _isDiscovering) ? null : _findPc,
                            icon: _isDiscovering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search, size: 18),
                            label: Text(_isDiscovering ? 'Searching…' : 'Find PC on Network'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00ACC1),
                              side: const BorderSide(color: Color(0xFF00ACC1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or enter manually', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _ipController,
                            enabled: !_isConnected,
                            decoration: const InputDecoration(
                              labelText: 'PC IP Address',
                              hintText: '192.168.1.x',
                              prefixIcon: Icon(Icons.computer_outlined),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _portController,
                            enabled: !_isConnected,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '8765',
                              prefixIcon: Icon(Icons.settings_ethernet),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isBusy ? null : (_isConnected ? _disconnect : _connect),
                            icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                            label: Text(_isConnected ? 'Disconnect' : 'Connect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isConnected ? Colors.red.shade700 : const Color(0xFFF57C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Sync card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.sync, color: Color(0xFF1A2744), size: 22),
                              SizedBox(width: 10),
                              Text('Send Scans to PC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scans will be typed directly into whichever field is active on the PC.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140)),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: (_isConnected && !_isBusy) ? _sync : null,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Sync Scans to PC'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2744),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Coming soon card for BT/USB
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bluetooth, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bluetooth & USB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Coming in a future update', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Soon', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),

          // Activity log
          Container(
            height: 130,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF243455) : const Color(0xFFCFD8DC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      const Text('Activity Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      if (_log.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _log.clear()),
                          child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _log.isEmpty
                      ? const Center(child: Text('No activity yet.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: _log.length,
                          itemBuilder: (_, i) => Text(
                            _log[i],
                            style: const TextStyle(fontSize: 11, height: 1.5),
                          ),
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

class _StatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool isBusy;
  const _StatusBanner({required this.isConnected, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: isConnected ? Colors.green.shade700 : const Color(0xFF37474F),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConnected ? 'Connected to PC — Scans will be sent automatically' : 'Not connected to PC',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
