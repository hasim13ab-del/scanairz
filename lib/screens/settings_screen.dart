import 'package:flutter/material.dart';
import 'package:scanairz/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  // PC Connection
  String _connectionMethod = 'Wi-Fi';
  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // Scanning Preferences
  bool _continuousScan = false;
  bool _vibration = true;
  bool _laserAnimation = true;

  // Storage Options
  bool _saveHistory = true;
  int _autoClearHistoryDays = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _settingsService.loadSettings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading settings'));
          } else {
            final settings = snapshot.data!;
            _connectionMethod = settings['connectionMethod']!;
            _ipAddressController.text = settings['ipAddress']!;
            _portController.text = settings['port']!;
            _continuousScan = settings['continuousScan']!;
            _vibration = settings['vibration']!;
            _laserAnimation = settings['laserAnimation']!;
            _saveHistory = settings['saveHistory']!;
            _autoClearHistoryDays = settings['autoClearHistoryDays']!;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('PC Server Connection'),
                _buildConnectionSettings(),
                const Divider(height: 32),
                _buildSectionTitle('Scanning Preferences'),
                _buildScanningPreferences(),
                const Divider(height: 32),
                _buildSectionTitle('Storage Options'),
                _buildStorageOptions(),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildConnectionSettings() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _connectionMethod,
          decoration: const InputDecoration(
            labelText: 'Connection Method',
            border: OutlineInputBorder(),
          ),
          items: ['Wi-Fi', 'Bluetooth', 'USB']
              .map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _connectionMethod = value;
              });
            }
          },
        ),
        if (_connectionMethod == 'Wi-Fi') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _ipAddressController,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              hintText: '192.168.1.100',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '8080',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildScanningPreferences() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Continuous Scan'),
          subtitle: const Text('Scan barcodes continuously without interruption'),
          value: _continuousScan,
          onChanged: (value) => setState(() => _continuousScan = value),
        ),
        SwitchListTile(
          title: const Text('Vibration on Scan'),
          subtitle: const Text('Vibrate the device when a barcode is detected'),
          value: _vibration,
          onChanged: (value) => setState(() => _vibration = value),
        ),
        SwitchListTile(
          title: const Text('Laser Animation'),
          subtitle: const Text('Show the red laser animation while scanning'),
          value: _laserAnimation,
          onChanged: (value) => setState(() => _laserAnimation = value),
        ),
      ],
    );
  }

  Widget _buildStorageOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Save Scan History'),
          subtitle: const Text('Keep a log of all scanned barcodes'),
          value: _saveHistory,
          onChanged: (value) => setState(() => _saveHistory = value),
        ),
        if (_saveHistory)
          ListTile(
            title: const Text('Auto-clear History'),
            trailing: DropdownButton<int>(
              value: _autoClearHistoryDays,
              items: [1, 7, 30, 90]
                  .map((days) => DropdownMenuItem(
                        value: days,
                        child: Text(days == 0 ? 'Never' : '$days days'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _autoClearHistoryDays = value;
                  });
                }
              },
            ),
          ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    await _settingsService.saveSettings(
      connectionMethod: _connectionMethod,
      ipAddress: _ipAddressController.text,
      port: _portController.text,
      continuousScan: _continuousScan,
      vibration: _vibration,
      laserAnimation: _laserAnimation,
      saveHistory: _saveHistory,
      autoClearHistoryDays: _autoClearHistoryDays,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }
}
