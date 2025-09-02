import 'package:flutter/material.dart';
import 'animated_scanning_line.dart';

class ScannerOverlay extends StatelessWidget {
  final AnimationController animationController;

  const ScannerOverlay({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // dynamic centered scan box (square 70% width)
    final boxSize = size.width * 0.7;
    final top = (size.height - boxSize) / 2;

    return Stack(
      children: [
        // Scanner box
        Positioned(
          top: top,
          left: (size.width - boxSize) / 2,
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Moving scan line
        AnimatedScanningLine(
          animationController: animationController,
          top: top,
          boxSize: boxSize,
        ),
      ],
    );
  }
}
