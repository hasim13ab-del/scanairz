
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/services/storage_service.dart';
import 'package:vibration/vibration.dart';

class SingleScanScreen extends StatefulWidget {
  const SingleScanScreen({super.key});

  @override
  State<SingleScanScreen> createState() => _SingleScanScreenState();
}

class _SingleScanScreenState extends State<SingleScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final MobileScannerController _scannerController = MobileScannerController();
  late SettingsService _settingsService;
  late StorageService _storageService;
  late PcConnector _pcConnector;

  Future<Map<String, dynamic>>? _settingsFuture;

  bool _continuousScan = false;
  bool _vibration = true;
  bool _laserAnimation = true;
  bool _saveHistory = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settingsFuture == null) {
      _settingsService = Provider.of<SettingsService>(context, listen: false);
      _storageService = Provider.of<StorageService>(context, listen: false);
      _pcConnector = Provider.of<PcConnector>(context, listen: false);
      _settingsFuture = _loadSettings();
    }
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    _continuousScan = settings['continuousScan'] ?? false;
    _vibration = settings['vibration'] ?? true;
    _laserAnimation = settings['laserAnimation'] ?? true;
    _saveHistory = settings['saveHistory'] ?? true;
    return settings;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double scanWindowSize = 250.0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () {
              _scannerController.toggleTorch();
            },
            tooltip: 'Torch',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading settings'));
            } else {
              return Center(
                child: SizedBox(
                  width: scanWindowSize,
                  height: scanWindowSize,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            _onBarcodeDetect(barcodes.first);
                          }
                        },
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
                      CustomPaint(
                        painter: BarcodeBoxPainter(),
                        child: const SizedBox(
                          width: scanWindowSize,
                          height: scanWindowSize,
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
          }),
    );
  }

  void _onBarcodeDetect(Barcode barcode) async {
    final scanResult = barcode.rawValue;
    if (scanResult == null) {
      return;
    }

    if (_vibration) {
      Vibration.vibrate(duration: 100);
    }

    final newScan = ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      barcode: scanResult,
      format: barcode.format.toString(),
      timestamp: DateTime.now(),
    );

    if (_saveHistory) {
      final history = await _storageService.loadHistory();
      history.add(newScan);
      await _storageService.saveHistory(history);
    }

    await _pcConnector.syncData([newScan]);

    if (!_continuousScan) {
      _scannerController.stop();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button!
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildDialogContent(context, scanResult),
          ),
        ).then((_) => _scannerController.start());
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned: $scanResult')),
        );
      }
    }
  }

  Widget _buildDialogContent(BuildContext context, String scanResult) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(
            top: 66.0, // Space for the icon
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
          ),
          margin: const EdgeInsets.only(top: 45.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              const Text(
                'Scan Successful!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                scanResult,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 24.0),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('SCAN AGAIN'),
                ),
              ),
            ],
          ),
        ),
        // Top Icon
        Positioned(
          left: 16.0,
          right: 16.0,
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            radius: 45.0,
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 50.0,
            ),
          ),
        ),
      ],
    );
  }
}

class BarcodeBoxPainter extends CustomPainter {
  final double cornerLength;
  final double strokeWidth;
  final Color color;

  BarcodeBoxPainter({
    this.cornerLength = 30.0,
    this.strokeWidth = 5.0,
    this.color = Colors.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Top-left corner
    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    // Top-right corner
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    // Bottom-left corner
    path.moveTo(0, size.height - cornerLength);
    path.lineTo(0, size.height);
    path.lineTo(cornerLength, size.height);

    // Bottom-right corner
    path.moveTo(size.width - cornerLength, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
