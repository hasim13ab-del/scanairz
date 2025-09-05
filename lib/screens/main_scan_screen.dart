
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/screens/batch_scan_screen.dart';
import 'package:scanairz/screens/help_guide_screen.dart';
import 'package:scanairz/screens/settings_screen.dart';
import 'package:scanairz/screens/single_scan_screen.dart';
import 'package:scanairz/services/remote_config_service.dart';

class MainScanScreen extends StatelessWidget {
  const MainScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanAiRZ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<RemoteConfigService>(
        builder: (context, remoteConfig, child) {
          final showHelpGuide = remoteConfig.showHelpGuide;
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16.0),
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: <Widget>[
              _buildScanOption(
                context,
                icon: Icons.qr_code_scanner,
                label: 'Single Scan',
                color: theme.colorScheme.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SingleScanScreen()),
                  );
                },
              ),
              _buildScanOption(
                context,
                icon: Icons.inventory,
                label: 'Batch Scan',
                color: theme.colorScheme.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BatchScanScreen()),
                  );
                },
              ),
              if (showHelpGuide)
                _buildScanOption(
                  context,
                  icon: Icons.help_outline,
                  label: 'Help & Guide',
                  color: theme.colorScheme.tertiary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpGuideScreen()),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScanOption(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: color.withAlpha(77),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
