import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isVibrationOn = true;
  bool _isSoundOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Vibrate on Scan'),
            value: _isVibrationOn,
            onChanged: (value) {
              setState(() {
                _isVibrationOn = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Play Sound on Scan'),
            value: _isSoundOn,
            onChanged: (value) {
              setState(() {
                _isSoundOn = value;
              });
            },
          ),
          ListTile(
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Scanairz',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 Scanairz',
              );
            },
          ),
        ],
      ),
    );
  }
}
