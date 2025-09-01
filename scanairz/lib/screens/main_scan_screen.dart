import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import '../providers/scanner_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/scanner_overlay.dart';
import '../models/scan_result.dart';

class MainScanScreen extends ConsumerStatefulWidget {
  const MainScanScreen({super.key});

  @override
  ConsumerState<MainScanScreen> createState() => _MainScanScreenState();
}

class _MainScanScreenState extends ConsumerState<MainScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;
  bool isFlashOn = false;
  bool isFrontCamera = false;
  late AnimationController _animationController;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true); // 🔥 continuous laser animation
    startScanning();
  }

  void startScanning() {
    setState(() {
      isScanning = true;
    });
    cameraController.start();
  }

  void stopScanning() {
    setState(() {
      isScanning = false;
    });
    cameraController.stop();
  }

  Future<void> toggleFlash() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash not available: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> switchCamera() async {
    try {
      await cameraController.switchCamera();
      setState(() {
        isFrontCamera = !isFrontCamera;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera switch failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void handleBarcode(Barcode barcode) {
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return;
    }

    if (barcode.rawValue != null) {
      _lastScanTime = now;

      // Save result
      ref.read(scanResultsProvider.notifier).addScanResult(
        ScanResult.fromData(barcode.rawValue!, barcode.format.name),
      );

      // Feedback
      Vibration.vibrate(duration: 200);

      // Show message
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Scanned: ${barcode.rawValue}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
      }

      // ❌ no animation restart needed, beam is continuous
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppTheme.darkNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: toggleFlash,
            color: isFlashOn ? AppTheme.primaryRed : Colors.white,
          ),
          IconButton(
            icon: Icon(isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                handleBarcode(barcode);
              }
            },
          ),
          ScannerOverlay(animationController: _animationController),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: isScanning ? stopScanning : startScanning,
                  backgroundColor: AppTheme.primaryRed,
                  child: Icon(isScanning ? Icons.stop : Icons.play_arrow),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.done),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }
}
