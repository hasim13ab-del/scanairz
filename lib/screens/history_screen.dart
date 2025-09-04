import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/providers/scanner_provider.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Rebuild the widget when the search text changes
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }
  
  Future<void> _exportHistory(List<ScanResult> scans) async {
    if (scans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No history to export.')),
      );
      return;
    }

    final List<List<dynamic>> rows = [];
    rows.add(['Barcode', 'Format', 'Timestamp']); // Header
    for (var scan in scans) {
      rows.add([
        scan.barcode,
        scan.format,
        DateFormat.yMMMd().add_jms().format(scan.timestamp),
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rows);
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/scan_history.csv';
    final File file = File(filePath);
    await file.writeAsString(csv);

    final xFile = XFile(filePath, mimeType: 'text/csv');
    Share.shareXFiles([xFile], subject: 'ScanAirz History Export');
  }


  @override
  Widget build(BuildContext context) {
    final allScans = ref.watch(scannedCodesProvider);
    final theme = Theme.of(context);

    // Filter the scans based on the search query and date range
    final filteredScans = allScans.where((scan) {
      final query = _searchController.text.toLowerCase();
      final barcodeMatch = scan.barcode.toLowerCase().contains(query);
      final dateMatch = _selectedDateRange == null
          ? true
          : scan.timestamp.isAfter(_selectedDateRange!.start) &&
              scan.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      return barcodeMatch && dateMatch;
    }).toList().reversed.toList(); // Show newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter by Date',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportHistory(filteredScans),
            tooltip: 'Export History',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by barcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: theme.colorScheme.surface)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: theme.colorScheme.secondary)
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '''From: ${DateFormat.yMMMd().format(_selectedDateRange!.start)}
To: ${DateFormat.yMMMd().format(_selectedDateRange!.end)}''',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                  )
                ],
              ),
            ),
          Expanded(
            child: filteredScans.isEmpty
                ? const Center(
                    child: Text(
                      'No matching scan results found.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredScans.length,
                    itemBuilder: (context, index) {
                      final result = filteredScans[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scanned on: ${DateFormat.yMMMd().add_jms().format(result.timestamp)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.share,
                                    color: theme.colorScheme.secondary),
                                onPressed: () => _shareResult(result),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: theme.colorScheme.error),
                                onPressed: () {
                                  ref
                                      .read(scannedCodesProvider.notifier)
                                      .removeScannedCode(result);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content:
              const Text('Are you sure you want to delete all scan results?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                ref.read(scannedCodesProvider.notifier).clearAll();
                _searchController.clear();
                setState(() {
                  _selectedDateRange = null;
                });
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
