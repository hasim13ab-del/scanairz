import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanairz/providers/scanner_provider.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/settings_service.dart';

class PcSyncScreen extends ConsumerStatefulWidget {
  const PcSyncScreen({super.key});

  @override
  ConsumerState<PcSyncScreen> createState() => _PcSyncScreenState();
}

class _PcSyncScreenState extends ConsumerState<PcSyncScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final List<String> _activityLog = [];

  late PcConnector _pcConnector;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _pcConnector = ref.read(pcConnectorProvider);
    _loadSettings();
    _pcConnector.connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _logActivity(isConnected ? 'Connected to PC' : 'Disconnected from PC');
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    _ipController.text = settings['ipAddress'] ?? '';
    _portController.text = settings['port'] ?? '';
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
    final scans = ref.read(scannedCodesProvider);
    if (scans.isEmpty) {
      _logActivity('No new scans to sync.');
      return;
    }

    try {
      _logActivity('Syncing ${scans.length} scans...');
      await _pcConnector.syncData(scans);
      _logActivity('Sync completed successfully.');
      ref.read(scannedCodesProvider.notifier).clearAll(); // Optionally clear after sync
    } catch (e) {
      _logActivity('Sync failed: $e');
    }
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
                color: _isConnected ? theme.colorScheme.secondary : theme.colorScheme.error,
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
          keyboardType: TextInputType.number,
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
                        vertical: 4.0, horizontal: 8.0),
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
