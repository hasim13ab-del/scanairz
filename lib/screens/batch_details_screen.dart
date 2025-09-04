import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanairz/models/batch.dart';
import 'package:share_plus/share_plus.dart';

class BatchDetailsScreen extends StatefulWidget {
  final Batch batch;

  const BatchDetailsScreen({super.key, required this.batch});

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  Future<void> _exportBatch() async {
    if (widget.batch.scans.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to export.')),
        );
      }
      return;
    }

    final List<List<dynamic>> rows = [];
    rows.add(['Barcode', 'Format', 'Timestamp']);
    for (final scan in widget.batch.scans) {
      rows.add([
        scan.barcode,
        scan.format,
        DateFormat.yMd().add_jms().format(scan.timestamp)
      ]);
    }

    String csv = rows.map((row) => row.join(',')).join('\n');

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'scanairz_${widget.batch.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final File file = File('${tempDir.path}/$fileName');

      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ScanAirZ Batch Export: ${widget.batch.name}',
        text:
            'Here is the batch "${widget.batch.name}" of scanned barcodes from ScanAirZ.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting batch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportBatch,
            tooltip: 'Export Batch',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanned on: ${DateFormat.yMMMd().add_jms().format(widget.batch.timestamp)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.batch.scans.length} items',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.batch.scans.length,
              itemBuilder: (context, index) {
                final scan = widget.batch.scans[index];
                return ListTile(
                  title: Text(scan.barcode),
                  subtitle: Text('Format: ${scan.format}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
