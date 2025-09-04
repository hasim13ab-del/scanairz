import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/providers/scanner_provider.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:vibration/vibration.dart';

class SingleScanScreen extends ConsumerStatefulWidget {
  const SingleScanScreen({super.key});

  @override
  ConsumerState<SingleScanScreen> createState() => _SingleScanScreenState();
}

class _SingleScanScreenState extends ConsumerState<SingleScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final MobileScannerController _scannerController = MobileScannerController();
  final SettingsService _settingsService = SettingsService();
  final PcConnector _pcConnector = PcConnector();

  late Future<Map<String, dynamic>> _settingsFuture;

  bool _continuousScan = false;
  bool _vibration = true;
  bool _laserAnimation = true;
  bool _saveHistory = true;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
                            _onBarcodeDetect(barcodes.first, ref);
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
                    ],
                  ),
                ),
              );
            }
          }),
    );
  }

  void _onBarcodeDetect(Barcode barcode, WidgetRef ref) async {
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
      ref.read(scannedCodesProvider.notifier).addScannedCode(newScan);
    }

    await _pcConnector.syncData([newScan]);

    if (!_continuousScan) {
      _scannerController.stop();
      if(mounted) {
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
      if(mounted) {
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
