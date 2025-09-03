import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scanairz/models/scan_result.dart';
import 'package:scanairz/providers/scanner_provider.dart';
import 'package:scanairz/services/permission_service.dart';

class MainScanScreen extends ConsumerStatefulWidget {
  const MainScanScreen({super.key});

  @override
  ConsumerState<MainScanScreen> createState() => _MainScanScreenState();
}

class _MainScanScreenState extends ConsumerState<MainScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late MobileScannerController _scannerController;
  final PermissionService _permissionService = PermissionService();
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Initialize the scanner controller
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      // The controller's analyzeImage property is true by default, which is what we want.
      // The old `allowDuplicates` is now managed manually in the onDetect callback.
    );

    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    await _permissionService.requestCameraPermission();
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _isCameraPermissionGranted = status == PermissionStatus.granted;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose(); // Dispose the scanner controller
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final scannedCodes = ref.read(scannedCodesProvider);
    final existingBarcodes = scannedCodes.map((e) => e.barcode).toSet();

    for (final barcode in capture.barcodes) {
      final codeValue = barcode.rawValue;
      if (codeValue != null && codeValue.isNotEmpty && !existingBarcodes.contains(codeValue)) {
        final scanResult = ScanResult.fromData(codeValue, barcode.format.toString());
        // Use read to call the method, which won't cause a rebuild here
        ref.read(scannedCodesProvider.notifier).addScannedCode(scanResult);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to rebuild the UI when the list changes
    final scannedCodes = ref.watch(scannedCodesProvider);

    return Scaffold(
      // AppBar to hold the flash toggle
      appBar: AppBar(
        title: const Text('Batch Scan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      // Extend body behind app bar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_isCameraPermissionGranted)
            MobileScanner(
              controller: _scannerController, // Use the state-managed controller
              onDetect: _onDetect,
            )
          else
            const Center(
              child: Text('Camera permission is required to scan barcodes.'),
            ),
          // ScannerOverlay(animationController: _animationController),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  "Scanned: ${scannedCodes.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 10),
                if (scannedCodes.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: scannedCodes.length,
                      itemBuilder: (context, index) {
                        // Display the most recent scans first
                        final scanResult = scannedCodes[scannedCodes.length - 1 - index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              scanResult.barcode,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
