import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/scan_result.dart';

class BarcodeScannerService {
  MobileScannerController controller = MobileScannerController();
  final StreamController<ScanResult> _scanResultController = StreamController<ScanResult>.broadcast();

  Stream<ScanResult> get scanResultStream => _scanResultController.stream;

  void startScanning() {
    controller.start();
  }

  void stopScanning() {
    controller.stop();
  }

  void onBarcodeDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final result = ScanResult.fromData(barcode.rawValue ?? 'Unknown', barcode.format.toString());
      _scanResultController.add(result);
    }
  }

  void toggleFlash() {
    controller.toggleTorch();
  }

  void switchCamera() {
    controller.switchCamera();
  }

  void dispose() {
    _scanResultController.close();
    controller.dispose();
  }
}