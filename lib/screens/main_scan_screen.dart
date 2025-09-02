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

class _MainScanScreenState extends ConsumerState<MainScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
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

  void toggleFlash() {
    cameraController.toggleTorch();
  }

  void switchCamera() {
    cameraController.switchCamera();
  }

  void handleBarcode(Barcode barcode) {
    if (barcode.rawValue != null) {
      // Add to scan results
      ref.read(scanResultsProvider.notifier).addScanResult(
        ScanResult.fromData(barcode.rawValue!, barcode.format.name),
      );
      
      // Provide feedback
      Vibration.vibrate(duration: 200);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned: ${barcode.rawValue}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppTheme.darkNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                handleBarcode(barcode);
              }
            },
          ),
          const ScannerOverlay(),
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
    cameraController.dispose();
    super.dispose();
  }
}