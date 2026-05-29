import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';

class PcSyncScreen extends StatefulWidget {
  const PcSyncScreen({super.key});

  @override
  State<PcSyncScreen> createState() => _PcSyncScreenState();
}

class _PcSyncScreenState extends State<PcSyncScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final List<String> _activityLog = [];

  late SettingsService _settingsService;
  late StorageService _storageService;
  late PcConnector _pcConnector;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isConnected = false;
  bool _settingsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _pcConnector = Provider.of<PcConnector>(context, listen: false);
    _isConnected = _pcConnector.isConnected;

    _connectionSubscription ??=
        _pcConnector.connectionStatus.listen(_handleConnectionChanged);

    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _ipController.text = settings['ipAddress'] ?? '';
      _portController.text = settings['port'] ?? '8765';
    });
  }

  void _handleConnectionChanged(bool isConnected) {
    if (!mounted) return;
    setState(() {
      _isConnected = isConnected;
      _activityLog.insert(
        0,
        '${DateTime.now().toLocal()}: ${isConnected ? 'Connected to PC' : 'Disconnected from PC'}',
      );
    });
  }

  void _logActivity(String message) {
    setState(() {
      _activityLog.insert(0, '${DateTime.now().toLocal()}: $message');
    });
  }

  Future<void> _connect() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      _logActivity('IP address and port cannot be empty.');
      return;
    }

    final ip = _ipController.text;
    final port = int.tryParse(_portController.text);
    if (port == null) {
      _logActivity('Invalid port number.');
      return;
    }

    _logActivity('Connecting to $ip:$port...');
    final success = await _pcConnector.connect(ip, port);
    if (!success) {
      _logActivity('Failed to connect.');
    }
  }

  void _disconnect() {
    _pcConnector.disconnect();
  }

  Future<void> _sync() async {
    if (!_isConnected) {
      _logActivity('Not connected. Cannot sync.');
      return;
    }

    final scans = await _storageService.loadScanResults();
    if (scans.isEmpty) {
      _logActivity('No new scans to sync.');
      return;
    }

    try {
      _logActivity('Syncing ${scans.length} scans...');
      await _pcConnector.syncData(scans);
      _logActivity('Sync completed successfully.');
      await _storageService.clearScanResults();
    } catch (e) {
      _logActivity('Sync failed: $e');
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PC Sync')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusSection(),
            const SizedBox(height: 20),
            _buildControlsSection(),
            const SizedBox(height: 20),
            _buildActivityLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isConnected ? 'Status: Connected' : 'Status: Disconnected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isConnected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ipController,
          decoration: const InputDecoration(labelText: 'PC IP Address'),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _portController,
          decoration: const InputDecoration(labelText: 'Port'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _isConnected ? null : _connect,
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: !_isConnected ? null : _disconnect,
              child: const Text('Disconnect'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isConnected ? _sync : null,
          child: const Text('Sync Now'),
        ),
      ],
    );
  }

  Widget _buildActivityLog() {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Activity Log',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.surface),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _activityLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Text(_activityLog[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
