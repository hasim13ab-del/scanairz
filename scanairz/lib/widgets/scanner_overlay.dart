import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  final AnimationController animationController;

  const ScannerOverlay({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerPainter(animationController.value), // no const here
          size: const Size(250, 250), // const is fine here
        );
      },
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final double progress;

  const _ScannerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw outer border
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, borderPaint);

    // Laser position
    final y = size.height * progress;

    // Draw scanning laser
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
