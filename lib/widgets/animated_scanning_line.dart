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
    return Positioned(
      top: top,
      left: (MediaQuery.of(context).size.width - boxSize) / 2,
      width: boxSize,
      height: boxSize,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animationController.value * boxSize),
            child: Container(
              height: 2,
              color: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
