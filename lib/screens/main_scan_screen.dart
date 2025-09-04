import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Assuming you are using Riverpod

class MainScanScreen extends ConsumerWidget { // Changed to ConsumerWidget if using Riverpod
  const MainScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Added WidgetRef if using Riverpod
    // Define the size of the scan preview window
    const double scanWindowSize = 250.0; // Adjust this size as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Scan'),
      ),
      body: Center(
        child: SizedBox(
          width: scanWindowSize,
          height: scanWindowSize,
          child: Stack(
            children: [
              // Camera preview
              MobileScanner(
                // fit: BoxFit.cover, // Adjust fit as needed
                onDetect: (capture) {
                  // Handle scan results here
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    debugPrint('Barcode found! ${barcode.rawValue}');
                    // You would typically display a dialog with the result here
                    // For now, we'll just print it.
                  }
                },
              ),

              // Green corner markers
              // Top-Left
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 30, // Length of the L-shape arm
                  height: 30, // Length of the L-shape arm
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.green, width: 3),
                      left: BorderSide(color: Colors.green, width: 3),
                    ),
                  ),
                ),
              ),
              // Top-Right
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.green, width: 3),
                      right: BorderSide(color: Colors.green, width: 3),
                    ),
                  ),
                ),
              ),
              // Bottom-Left
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.green, width: 3),
                      left: BorderSide(color: Colors.green, width: 3),
                    ),
                  ),
                ),
              ),
              // Bottom-Right
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.green, width: 3),
                      right: BorderSide(color: Colors.green, width: 3),
                    ),
                  ),
                ),
              ),

              // The red scanning beam will be added here in the next step
            ],
          ),
        ),
      ),
    );
  }
}
