import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/scan_result.dart';
import '../../providers/scanner_provider.dart';
import '../../services/permission_service.dart';
import '../../widgets/scanner_overlay.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final PermissionService _permissionService = PermissionService();
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    await _permissionService.requestCameraPermission();
    final status = await Permission.camera.status;
    setState(() {
      _isCameraPermissionGranted = status == PermissionStatus.granted;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcode) {
    for (final code in barcode.barcodes) {
      final value = code.rawValue ?? '';
      if (value.isNotEmpty) {
        final scanResult = ScanResult.fromData(value, code.format.toString());
        ref.read(scannedCodesProvider.notifier).addScannedCode(scanResult);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannedCodes = ref.watch(scannedCodesProvider);

    return Scaffold(
      body: Stack(
        children: [
          if (_isCameraPermissionGranted)
            MobileScanner(
              controller: MobileScannerController(
                facing: CameraFacing.back,
                torchEnabled: false,
              ),
              onDetect: _onDetect,
            )
          else
            const Center(
              child: Text('Camera permission is required to scan barcodes.'),
            ),
          ScannerOverlay(animationController: _controller),
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
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: scannedCodes.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            scannedCodes[index].barcode,
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
