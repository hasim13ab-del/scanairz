
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/screens/about_screen.dart';
import 'package:scanairz/screens/help_guide_screen.dart';
import 'package:scanairz/services/network_discovery_service.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/theme_notifier.dart';
import 'package:scanairz/themes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final NetworkDiscoveryService _networkDiscoveryService =
      NetworkDiscoveryService();

  // PC Connection
  String _connectionMethod = 'Wi-Fi';
  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  List<String> _discoveredDevices = [];
  bool _isDiscovering = false;

  // Scanning Preferences
  bool _continuousScan = false;
  bool _vibration = true;
  bool _laserAnimation = true;

  // Storage Options
  bool _saveHistory = true;
  int _autoClearHistoryDays = 7;

  // Appearance
  String _theme = 'System';

  @override
  void initState() {
    super.initState();
    _networkDiscoveryService.discoveredDevices.listen((devices) {
      setState(() {
        _discoveredDevices = devices;
      });
    });
  }

  @override
  void dispose() {
    _networkDiscoveryService.dispose();
    _ipAddressController.dispose();
    _portController.dispose();
    super.dispose();
  }

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
            _theme = settings['theme'] ?? 'System';

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
                const Divider(height: 32),
                _buildSectionTitle('Appearance'),
                _buildThemeSettings(),
                const Divider(height: 32),
                _buildSectionTitle('About'),
                _buildHelpAndAbout(),
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
      style: Theme.of(context).textTheme.titleLarge,
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
          ElevatedButton(
            onPressed: () {
              if (_isDiscovering) {
                _networkDiscoveryService.stopDiscovery();
              } else {
                _networkDiscoveryService.startDiscovery();
              }
              setState(() {
                _isDiscovering = !_isDiscovering;
              });
            },
            child: Text(_isDiscovering ? 'Stop Scanning' : 'Scan for Devices'),
          ),
          if (_isDiscovering)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_discoveredDevices.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final deviceIp = _discoveredDevices[index];
                  return ListTile(
                    title: Text(deviceIp),
                    onTap: () {
                      setState(() {
                        _ipAddressController.text = deviceIp;
                      });
                    },
                  );
                },
              ),
            ),
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

  Widget _buildThemeSettings() {
    return DropdownButtonFormField<String>(
      value: _theme,
      decoration: const InputDecoration(
        labelText: 'Theme',
        border: OutlineInputBorder(),
      ),
      items: ['Light', 'Dark', 'System']
          .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _theme = value;
          });
        }
      },
    );
  }

  Widget _buildHelpAndAbout() {
    return Column(
      children: [
        ListTile(
          title: const Text('Help'),
          leading: const Icon(Icons.help_outline),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpGuideScreen(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('About'),
          leading: const Icon(Icons.info_outline),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AboutScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    if (_theme == 'Light') {
      themeNotifier.setTheme(AppThemes.lightTheme);
    } else if (_theme == 'Dark') {
      themeNotifier.setTheme(AppThemes.darkTheme);
    } else {
      // System theme
      final brightness = MediaQuery.of(context).platformBrightness;
      if (brightness == Brightness.dark) {
        themeNotifier.setTheme(AppThemes.darkTheme);
      } else {
        themeNotifier.setTheme(AppThemes.lightTheme);
      }
    }

    await _settingsService.saveSettings(
      connectionMethod: _connectionMethod,
      ipAddress: _ipAddressController.text,
      port: _portController.text,
      continuousScan: _continuousScan,
      vibration: _vibration,
      laserAnimation: _laserAnimation,
      saveHistory: _saveHistory,
      autoClearHistoryDays: _autoClearHistoryDays,
      theme: _theme,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }
}
