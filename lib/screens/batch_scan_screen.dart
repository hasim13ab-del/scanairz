import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/models/batch.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/permission_service.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

class BatchScanScreen extends StatefulWidget {
  const BatchScanScreen({super.key});

  @override
  State<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends State<BatchScanScreen>
    with SingleTickerProviderStateMixin {
  final List<ScanResult> _scannedBarcodes = [];
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();
  late SettingsService _settingsService;
  late StorageService _storageService;
  Future<void>? _loadSettingsFuture;
  late AnimationController _animationController;
  bool _vibration = true;
  bool _laserAnimation = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initScanner();
  }

  Future<void> _initScanner() async {
    final permissionService = Provider.of<PermissionService>(context, listen: false);
    await permissionService.requestCameraPermission();
    if (mounted) {
      _scannerController.start();
      _scannerController.setZoom(0.1);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadSettingsFuture == null) {
      _settingsService = Provider.of<SettingsService>(context, listen: false);
      _storageService = Provider.of<StorageService>(context, listen: false);
      _loadSettingsFuture = _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    if (mounted) {
      setState(() {
        _vibration = settings['vibration'] ?? true;
        _laserAnimation = settings['laserAnimation'] ?? true;
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && mounted) {
        if (_scannedBarcodes.isEmpty ||
            _scannedBarcodes.last.barcode != barcode.rawValue) {
          final newScan = ScanResult(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            barcode: barcode.rawValue!,
            format: barcode.format.toString(),
            timestamp: DateTime.now(),
          );
          
          setState(() {
            _scannedBarcodes.add(newScan);
          });
          
          if (_vibration) Vibration.vibrate(duration: 80);
          _audioPlayer.play(AssetSource('sounds/beep.mp3'));

          // Continuous Sync if connected
          final pcConnector = Provider.of<PcConnector>(context, listen: false);
          if (pcConnector.isConnected) {
            try {
              await pcConnector.syncData([newScan]);
            } catch (_) {}
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Viewfinder takes up ~40% of screen height in batch mode (list needs room below)
    final double viewfinderHeight = size.height * 0.40;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Scan'),
        actions: [
          if (_scannedBarcodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ACC1).withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00ACC1).withAlpha(80)),
                  ),
                  child: Text(
                    '${_scannedBarcodes.length} scanned',
                    style: const TextStyle(
                      color: Color(0xFF26C6DA),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Torch',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _scannedBarcodes.isEmpty
                ? null
                : () => setState(() => _scannedBarcodes.clear()),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera viewfinder
          SizedBox(
            height: viewfinderHeight,
            width: double.infinity,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  scanWindow: Rect.fromLTWH(0, 0, size.width, viewfinderHeight),
                  onDetect: _onBarcodeDetected,
                ),
                // Laser animation
                if (_laserAnimation)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) => Positioned(
                      top: viewfinderHeight * _animationController.value - 1,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF00ACC1),
                              Color(0xFF00ACC1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00ACC1).withAlpha(150),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Corner brackets overlay
                CustomPaint(
                  painter: _BatchCornerPainter(),
                  child: SizedBox(width: double.infinity, height: viewfinderHeight),
                ),
                // "Scanning..." label
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(130),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Scanning continuously — aim at barcode',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanned list header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                const Text(
                  'Scanned Items',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_scannedBarcodes.isNotEmpty)
                  Text(
                    '${_scannedBarcodes.length} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scanned list
          Expanded(
            child: _scannedBarcodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items scanned yet',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scannedBarcodes.length,
                    itemBuilder: (context, index) {
                      final scan = _scannedBarcodes.reversed.toList()[index];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ACC1).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${_scannedBarcodes.length - index}',
                              style: const TextStyle(
                                color: Color(0xFF00ACC1),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          scan.barcode,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat('HH:mm:ss').format(scan.timestamp),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          color: theme.colorScheme.error,
                          onPressed: () {
                            setState(() => _scannedBarcodes.remove(scan));
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Action buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scannedBarcodes.isEmpty ? null : _showSaveBatchDialog,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Batch'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A2744),
                        side: const BorderSide(color: Color(0xFF1A2744)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scannedBarcodes.isEmpty ? null : _exportBatch,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveBatchDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Batch'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Batch name',
            hintText: 'e.g. Warehouse A — Monday',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final newBatch = Batch(
                name: controller.text.trim(),
                timestamp: DateTime.now(),
                scans: List<ScanResult>.from(_scannedBarcodes),
              );
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              final batches = await _storageService.loadBatches();
              batches.add(newBatch);
              await _storageService.saveBatches(batches);
              setState(() => _scannedBarcodes.clear());
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Batch saved!')),
              );
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
      messenger.showSnackBar(const SnackBar(content: Text('No items to export.')));
      return;
    }
    final rows = <List<dynamic>>[
      ['Barcode', 'Format', 'Timestamp'],
      ..._scannedBarcodes.map((s) => [
            s.barcode,
            s.format,
            DateFormat('yyyy-MM-dd HH:mm:ss').format(s.timestamp),
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'scanairz_batch_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ScanAiRZ Batch Export',
        text: 'Scanned barcodes from ScanAiRZ.',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }
}

class _BatchCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 30.0;
    const sw = 3.5;
    final paint = Paint()
      ..color = const Color(0xFF00ACC1)
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 20.0;
    final path = Path();
    // Top-left
    path.moveTo(margin, margin + len); path.lineTo(margin, margin); path.lineTo(margin + len, margin);
    // Top-right
    path.moveTo(size.width - margin - len, margin); path.lineTo(size.width - margin, margin); path.lineTo(size.width - margin, margin + len);
    // Bottom-left
    path.moveTo(margin, size.height - margin - len); path.lineTo(margin, size.height - margin); path.lineTo(margin + len, size.height - margin);
    // Bottom-right
    path.moveTo(size.width - margin - len, size.height - margin); path.lineTo(size.width - margin, size.height - margin); path.lineTo(size.width - margin, size.height - margin - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BatchCornerPainter old) => false;
}
