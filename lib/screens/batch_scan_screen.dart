import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_result_card.dart';
import 'main_scan_screen.dart';

class BatchScanScreen extends ConsumerWidget {
  const BatchScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanResults = ref.watch(scanResultsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('Batch Scan'),
        backgroundColor: AppTheme.darkNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainScanScreen()),
              );
            },
          ),
          if (scanResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(scanResultsProvider.notifier).clearAll();
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainScanScreen()),
          );
        },
        backgroundColor: AppTheme.primaryRed,
        child: const Icon(Icons.scanner),
      ),
      body: Column(
        children: [
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.scanner, size: 64, color: Colors.white70),
                        const SizedBox(height: 16),
                        const Text(
                          'No scans yet',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the scanner button to start',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MainScanScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                          ),
                          child: const Text('Start Scanning'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final result = scanResults[index];
                      return ScanResultCard(
                        result: result,
                        onDelete: () {
                          ref.read(scanResultsProvider.notifier).removeScanResult(result.id);
                        },
                        onEdit: () {
                          // Edit functionality would go here
                        },
                      );
                    },
                  ),
          ),
          if (scanResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Save batch functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Batch saved successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                      ),
                      child: const Text('Save Batch'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Export functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export functionality coming soon'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Export'),
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