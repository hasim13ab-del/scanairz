import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/providers/scanner_provider.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannedCodes = ref.watch(scannedCodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
      body: scannedCodes.isEmpty
          ? const Center(
              child: Text(
                'No scan results yet.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: scannedCodes.length,
              itemBuilder: (context, index) {
                final result = scannedCodes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      result.barcode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Format: ${result.format}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scanned on: ${DateFormat.yMMMd().add_jms().format(result.timestamp)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.share, color: Colors.blueAccent),
                      onPressed: () => _shareResult(result),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content: const Text('Are you sure you want to delete all scan results?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
              onPressed: () {
                ref.read(scannedCodesProvider.notifier).clearAll();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _shareResult(ScanResult result) {
    final text = 'Scanned Barcode:\n'
        'Value: ${result.barcode}\n'
        'Format: ${result.format}\n'
        'Timestamp: ${DateFormat.yMMMd().add_jms().format(result.timestamp)}';

    Share.share(text);
  }
}
