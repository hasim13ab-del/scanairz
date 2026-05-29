import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/permission_service.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';

class PcConnectionScreen extends StatefulWidget {
  const PcConnectionScreen({super.key});

  @override
  State<PcConnectionScreen> createState() => _PcConnectionScreenState();
}

class _PcConnectionScreenState extends State<PcConnectionScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8765');
  late TabController _tabController;

  // Services (injected)
  late PcConnector _pcConnector;
  late SettingsService _settingsService;
  late StorageService _storageService;
  late PermissionService _permissionService;

  // State
  StreamSubscription<bool>? _connSub;
  bool _isConnected = false;
  bool _isBusy = false;
  String _statusMessage = 'Not connected';
  final List<String> _log = [];

  // Bluetooth
  List<BluetoothDevice> _btDevices = [];
  BluetoothDevice? _selectedBtDevice;

  // USB
  List<UsbDevice> _usbDevices = [];
  UsbDevice? _selectedUsbDevice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pcConnector = Provider.of<PcConnector>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _permissionService = Provider.of<PermissionService>(context, listen: false);
    _isConnected = _pcConnector.isConnected;
    _connSub ??=
        _pcConnector.connectionStatus.listen(_onConnectionChanged);
    _loadWifiSettings();
  }

  Future<void> _loadWifiSettings() async {
    final s = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _ipController.text = s['ipAddress'] ?? '';
      _portController.text = s['port'] ?? '8765';
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    // Load device lists on tab switch
    if (_tabController.index == 1) _loadBluetoothDevices();
    if (_tabController.index == 2) _loadUsbDevices();
  }

  void _onConnectionChanged(bool connected) {
    if (!mounted) return;
    setState(() {
      _isConnected = connected;
      _statusMessage =
          connected ? '✅ Connected via ${_pcConnector.activeType.name.toUpperCase()}' : '🔴 Disconnected';
      _addLog(_statusMessage);
    });
  }

  void _addLog(String msg) {
    setState(() => _log.insert(0, '[${TimeOfDay.now().format(context)}] $msg'));
  }

  // ── WiFi ──────────────────────────────────────────────────────────────────
  Future<void> _connectWifi() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (ip.isEmpty || port == null) {
      _addLog('Enter a valid IP and port.');
      return;
    }
    setState(() { _isBusy = true; _statusMessage = 'Connecting via WiFi…'; });
    _addLog('Connecting to $ip:$port via WiFi…');
    final ok = await _pcConnector.connectWifi(ip, port);
    setState(() => _isBusy = false);
    if (!ok) _addLog('WiFi connection failed. Check IP and port.');
  }

  // ── Bluetooth ─────────────────────────────────────────────────────────────
  Future<void> _loadBluetoothDevices() async {
    await _permissionService.requestBluetoothPermissions();
    setState(() { _isBusy = true; _addLog('Scanning for paired BT devices…'); });
    _btDevices = await _pcConnector.getBluetoothDevices();
    setState(() { _isBusy = false; });
    if (_btDevices.isEmpty) _addLog('No paired Bluetooth devices found.');
  }

  Future<void> _connectBluetooth() async {
    if (_selectedBtDevice == null) {
      _addLog('Select a Bluetooth device first.');
      return;
    }
    setState(() { _isBusy = true; _statusMessage = 'Connecting via Bluetooth…'; });
    _addLog('Connecting to ${_selectedBtDevice!.name}…');
    final ok =
        await _pcConnector.connectBluetooth(_selectedBtDevice!.address);
    setState(() => _isBusy = false);
    if (!ok) _addLog('Bluetooth connection failed.');
  }

  // ── USB ───────────────────────────────────────────────────────────────────
  Future<void> _loadUsbDevices() async {
    setState(() { _isBusy = true; _addLog('Detecting USB devices…'); });
    _usbDevices = await _pcConnector.getUsbDevices();
    setState(() { _isBusy = false; });
    if (_usbDevices.isEmpty) _addLog('No USB serial devices found. Connect your device via OTG cable.');
  }

  Future<void> _connectUsb() async {
    if (_selectedUsbDevice == null) {
      _addLog('Select a USB device first.');
      return;
    }
    setState(() { _isBusy = true; _statusMessage = 'Connecting via USB…'; });
    _addLog('Connecting to ${_selectedUsbDevice!.productName}…');
    final ok = await _pcConnector.connectUsb(_selectedUsbDevice!);
    setState(() => _isBusy = false);
    if (!ok) _addLog('USB connection failed. Try reconnecting the cable.');
  }

  // ── Sync ──────────────────────────────────────────────────────────────────
  Future<void> _sync() async {
    if (!_isConnected) { _addLog('Not connected.'); return; }
    final scans = await _storageService.loadScanResults();
    if (scans.isEmpty) { _addLog('No scans to sync.'); return; }
    setState(() => _isBusy = true);
    _addLog('Syncing ${scans.length} scans…');
    try {
      await _pcConnector.syncData(scans);
      await _storageService.clearScanResults();
      _addLog('✅ Sync complete!');
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
    _ipController.dispose();
    _portController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Connection'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
            Tab(icon: Icon(Icons.usb), text: 'USB'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(theme),
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
          _buildActionBar(theme),
          _buildActivityLog(theme),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
      child: Row(
        children: [
          Icon(_isConnected ? Icons.check_circle : Icons.cancel,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isBusy) const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  // ── WiFi Tab ──────────────────────────────────────────────────────────────
  Widget _buildWifiTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.wifi, size: 48, color: Colors.blue),
          const SizedBox(height: 12),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'PC IP Address',
              prefixIcon: Icon(Icons.computer),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port (default 8765)',
              prefixIcon: Icon(Icons.settings_ethernet),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isBusy || _isConnected ? null : _connectWifi,
            icon: const Icon(Icons.wifi_find),
            label: const Text('Connect via WiFi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bluetooth Tab ─────────────────────────────────────────────────────────
  Widget _buildBluetoothTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.bluetooth, size: 28, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Paired Devices',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              TextButton.icon(
                onPressed: _isBusy ? null : _loadBluetoothDevices,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Scan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _btDevices.isEmpty
                ? const Center(
                    child: Text('Tap Scan to find paired Bluetooth devices.\n'
                        'Make sure your PC companion app is running and paired.',
                        textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: _btDevices.length,
                    itemBuilder: (_, i) {
                      final d = _btDevices[i];
                      return RadioListTile<BluetoothDevice>(
                        title: Text(d.name ?? 'Unknown'),
                        subtitle: Text(d.address),
                        value: d,
                        groupValue: _selectedBtDevice,
                        onChanged: (v) =>
                            setState(() => _selectedBtDevice = v),
                        secondary: const Icon(Icons.bluetooth_connected,
                            color: Colors.indigo),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isBusy || _isConnected || _selectedBtDevice == null
                ? null
                : _connectBluetooth,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Connect via Bluetooth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── USB Tab ───────────────────────────────────────────────────────────────
  Widget _buildUsbTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.usb, size: 28, color: Colors.teal),
                SizedBox(width: 8),
                Text('USB Devices',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              TextButton.icon(
                onPressed: _isBusy ? null : _loadUsbDevices,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Detect'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _usbDevices.isEmpty
                ? const Center(
                    child: Text(
                        'Connect your PC via OTG USB cable, then tap Detect.',
                        textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: _usbDevices.length,
                    itemBuilder: (_, i) {
                      final d = _usbDevices[i];
                      return RadioListTile<UsbDevice>(
                        title:
                            Text(d.productName ?? 'Unknown USB Device'),
                        subtitle: Text(
                            'VID: ${d.vid}  PID: ${d.pid}'),
                        value: d,
                        groupValue: _selectedUsbDevice,
                        onChanged: (v) =>
                            setState(() => _selectedUsbDevice = v),
                        secondary:
                            const Icon(Icons.usb, color: Colors.teal),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isBusy || _isConnected || _selectedUsbDevice == null
                ? null
                : _connectUsb,
            icon: const Icon(Icons.usb_rounded),
            label: const Text('Connect via USB'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────
  Widget _buildActionBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isConnected && !_isBusy ? _sync : null,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isConnected ? _disconnect : null,
            icon: const Icon(Icons.link_off),
            label: const Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity log ──────────────────────────────────────────────────────────
  Widget _buildActivityLog(ThemeData theme) {
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text('Activity Log',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(_log[i],
                  style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
