import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanairz/models/batch.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

class BatchScanScreen extends ConsumerStatefulWidget {
  const BatchScanScreen({super.key});

  @override
  ConsumerState<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends ConsumerState<BatchScanScreen>
    with SingleTickerProviderStateMixin {
  final List<ScanResult> _scannedBarcodes = [];
  final MobileScannerController _scannerController = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SettingsService _settingsService = SettingsService();

  late AnimationController _animationController;

  bool _vibration = true;
  bool _laserAnimation = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _vibration = settings['vibration'] ?? true;
      _laserAnimation = settings['laserAnimation'] ?? true;
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && mounted) {
        // To prevent rapid-fire scanning of the same barcode
        if (_scannedBarcodes.isEmpty ||
            _scannedBarcodes.last.barcode != barcode.rawValue) {
          setState(() {
            _scannedBarcodes.add(ScanResult(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              barcode: barcode.rawValue!,
              format: barcode.format.toString(),
              timestamp: DateTime.now(),
            ));
          });
          if (_vibration) {
            Vibration.vibrate(duration: 100);
          }
          _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double scanWindowSize = 250.0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _scannedBarcodes.clear();
              });
            },
            tooltip: 'Clear Scans',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: scanWindowSize,
            width: double.infinity,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                ),
                if (_laserAnimation)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: scanWindowSize * _animationController.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.secondary.withAlpha(204),
                                blurRadius: 5.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Scanned Items:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _scannedBarcodes.isEmpty
                ? const Center(
                    child: Text('Scan an item to begin.'),
                  )
                : ListView.builder(
                    itemCount: _scannedBarcodes.length,
                    itemBuilder: (context, index) {
                      final scanResult =
                          _scannedBarcodes.reversed.toList()[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        child: ListTile(
                          title: Text(scanResult.barcode),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                _scannedBarcodes.remove(scanResult);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _scannedBarcodes.isEmpty
                      ? null
                      : () => _showSaveBatchDialog(),
                  child: const Text('Save Batch'),
                ),
                ElevatedButton(
                  onPressed: _scannedBarcodes.isEmpty
                      ? null
                      : () => _exportBatch(),
                  child: const Text('Export Batch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveBatchDialog() {
    final batchNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Batch'),
        content: TextField(
          controller: batchNameController,
          decoration: const InputDecoration(hintText: 'Enter batch name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (batchNameController.text.isNotEmpty) {
                final newBatch = Batch(
                  name: batchNameController.text,
                  timestamp: DateTime.now(),
                  scans: _scannedBarcodes,
                );
                final storageService = StorageService();
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final batches = await storageService.loadBatches();
                batches.add(newBatch);
                await storageService.saveBatches(batches);
                setState(() {
                  _scannedBarcodes.clear();
                });
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Batch saved successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBatch() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_scannedBarcodes.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No items to export.')),
      );
      return;
    }

    final List<List<dynamic>> rows = [];
    rows.add(['Barcode', 'Format', 'Timestamp']);
    for (final scan in _scannedBarcodes) {
      rows.add([
        scan.barcode,
        scan.format,
        DateFormat.yMd().add_jms().format(scan.timestamp)
      ]);
    }

    final String csv = rows.map((row) => row.join(',')).join('\n');

    try {
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName = 'scanairz_batch_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final File file = File('${tempDir.path}/$fileName');

        await file.writeAsString(csv);

        await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'ScanAirZ Batch Export',
            text: 'Here is the batch of scanned barcodes from ScanAirZ.',
        );
    } catch (e) {
        messenger.showSnackBar(
            SnackBar(content: Text('Error exporting batch: $e')),
        );
    }
  }
}
