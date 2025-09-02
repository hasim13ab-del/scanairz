import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PcSyncScreen extends StatefulWidget {
  const PcSyncScreen({super.key});

  @override
  State<PcSyncScreen> createState() => _PcSyncScreenState();
}

class _PcSyncScreenState extends State<PcSyncScreen> {
  bool isSyncing = false;
  String syncStatus = 'Ready to sync';

  Future<void> startSync() async {
    setState(() {
      isSyncing = true;
      syncStatus = 'Syncing with PC...';
    });

    // Simulate sync process
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isSyncing = false;
      syncStatus = 'Sync completed successfully';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('PC Sync'),
        backgroundColor: AppTheme.darkNavy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xCC0A0E21),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.computer, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'PC Sync',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      syncStatus,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSyncing ? null : startSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(
                        isSyncing ? 'Syncing...' : 'Start Sync',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sync Instructions:',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Ensure your PC is on the same network\n'
              '2. Open Scanairz Desktop application\n'
              '3. Click "Start Sync" to begin the process',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}