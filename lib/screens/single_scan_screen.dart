import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/services/permission_service.dart';
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
  bool _isHandlingScan = false;

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
    }
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
    final size = MediaQuery.of(context).size;
    final double scanWindowSize = size.width * 0.82;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Single Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined, color: Colors.white),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Torch',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading settings', style: TextStyle(color: Colors.white)));
          }
          return Stack(
            children: [
              // Full-screen camera preview
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerController,
                  scanWindow: Rect.fromCenter(
                    center: Offset(size.width / 2, size.height / 2),
                    width: scanWindowSize,
                    height: scanWindowSize,
                  ),
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      _onBarcodeDetect(barcodes.first);
                    }
                  },
                ),
              ),

              // Dark overlay with transparent scan window
              Positioned.fill(
                child: _ScanOverlay(
                  scanWindowSize: scanWindowSize,
                  laserAnimation: _laserAnimation,
                  animationController: _animationController,
                  accentColor: theme.colorScheme.primary,
                ),
              ),

              // Bottom hint
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'Align barcode within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_continuousScan)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ACC1).withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00ACC1).withAlpha(80)),
                          ),
                          child: const Text(
                            'Continuous mode ON',
                            style: TextStyle(color: Color(0xFF26C6DA), fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onBarcodeDetect(Barcode barcode) async {
    if (_isHandlingScan) return;
    final scanResult = barcode.rawValue;
    if (scanResult == null) return;

    _isHandlingScan = true;

    if (_vibration) Vibration.vibrate(duration: 100);

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

    if (_pcConnector.isConnected) {
      try {
        await _pcConnector.syncData([newScan]);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PC sync failed: $e')),
          );
        }
      }
    }

    if (!_continuousScan) {
      _scannerController.stop();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _ScanResultDialog(
            scanResult: scanResult,
            onScanAgain: () {
              Navigator.of(ctx).pop();
              _isHandlingScan = false;
              if (mounted) _scannerController.start();
            },
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned: $scanResult'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      _isHandlingScan = false;
    }
  }
}

// ── Scan overlay with transparent cutout ──────────────────────────────────────
class _ScanOverlay extends StatelessWidget {
  final double scanWindowSize;
  final bool laserAnimation;
  final AnimationController animationController;
  final Color accentColor;

  const _ScanOverlay({
    required this.scanWindowSize,
    required this.laserAnimation,
    required this.animationController,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(scanWindowSize: scanWindowSize),
      child: Center(
        child: SizedBox(
          width: scanWindowSize,
          height: scanWindowSize,
          child: Stack(
            children: [
              // Corner brackets
              CustomPaint(
                painter: _CornerPainter(color: const Color(0xFF00ACC1)),
                child: SizedBox(width: scanWindowSize, height: scanWindowSize),
              ),
              // Laser animation
              if (laserAnimation)
                AnimatedBuilder(
                  animation: animationController,
                  builder: (context, _) => Positioned(
                    top: scanWindowSize * animationController.value - 1,
                    left: 12,
                    right: 12,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF00ACC1),
                            const Color(0xFF00ACC1),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00ACC1).withAlpha(180),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanWindowSize;

  const _OverlayPainter({required this.scanWindowSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(160);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final half = scanWindowSize / 2;
    final rect = Rect.fromLTRB(
      centerX - half, centerY - half,
      centerX + half, centerY + half,
    );
    final fullRect = Offset.zero & size;
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanWindowSize != scanWindowSize;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const sw = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Top-left
    path.moveTo(0, len); path.lineTo(0, 0); path.lineTo(len, 0);
    // Top-right
    path.moveTo(size.width - len, 0); path.lineTo(size.width, 0); path.lineTo(size.width, len);
    // Bottom-left
    path.moveTo(0, size.height - len); path.lineTo(0, size.height); path.lineTo(len, size.height);
    // Bottom-right
    path.moveTo(size.width - len, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, size.height - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ── Scan result dialog ────────────────────────────────────────────────────────
class _ScanResultDialog extends StatelessWidget {
  final String scanResult;
  final VoidCallback onScanAgain;

  const _ScanResultDialog({required this.scanResult, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00ACC1).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00ACC1), size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan Successful!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              scanResult,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onScanAgain,
          child: const Text('SCAN AGAIN', style: TextStyle(color: Color(0xFF00ACC1), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
