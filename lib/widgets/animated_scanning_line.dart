import 'package:flutter/material.dart';

class AnimatedScanningLine extends StatelessWidget {
  final AnimationController animationController;
  final double top;
  final double boxSize;

  const AnimatedScanningLine({
    super.key,
    required this.animationController,
    required this.top,
    required this.boxSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Positioned(
          top: top + (animationController.value * boxSize),
          left: (MediaQuery.of(context).size.width - boxSize) / 2,
          child: Container(
            width: boxSize,
            height: 3,
            color: Colors.redAccent,
          ),
        );
      },
    );
  }
}
