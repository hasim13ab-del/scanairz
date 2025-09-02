import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool autoSave = true;
    bool cloudBackup = false;
    bool vibrationFeedback = true;
    bool soundFeedback = true;

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.darkNavy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Scan Settings',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Auto Save Scans', style: TextStyle(color: Colors.white)),
            value: autoSave,
            onChanged: (value) {
              // Update auto save setting
            },
            activeTrackColor: AppTheme.primaryRed,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryRed),
          ),
          SwitchListTile(
            title: const Text('Vibration Feedback', style: TextStyle(color: Colors.white)),
            value: vibrationFeedback,
            onChanged: (value) {
              // Update vibration setting
            },
            activeTrackColor: AppTheme.primaryRed,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryRed),
          ),
          SwitchListTile(
            title: const Text('Sound Feedback', style: TextStyle(color: Colors.white)),
            value: soundFeedback,
            onChanged: (value) {
              // Update sound setting
            },
            activeTrackColor: AppTheme.primaryRed,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryRed),
          ),
          const Divider(color: Colors.white24),
          const Text(
            'Sync Settings',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Cloud Backup', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Backup scans to cloud storage', style: TextStyle(color: Colors.white70)),
            value: cloudBackup,
            onChanged: (value) {
              // Update cloud backup setting
            },
            activeTrackColor: AppTheme.primaryRed,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryRed),
          ),
          ListTile(
            title: const Text('PC Sync', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Sync with desktop application', style: TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              Navigator.pushNamed(context, '/sync');
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
        ],
      ),
    );
  }
}