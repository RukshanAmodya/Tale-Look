import 'package:flutter/material.dart';

class FaceGuidelinePainter extends CustomPainter {
  final double centerX;
  final double centerY;

  FaceGuidelinePainter({required this.centerX, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final shortestSide = size.shortestSide;
    
    final rect = Rect.fromCenter(
      center: Offset(size.width * centerX, size.height * centerY),
      width: shortestSide * 0.72,
      height: shortestSide * 0.88,
    );
    canvas.drawOval(rect, paint);
    
    canvas.drawLine(
      Offset(size.width * centerX, size.height * (centerY - 0.2)),
      Offset(size.width * centerX, size.height * (centerY + 0.2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceGuidelinePainter oldDelegate) {
    return oldDelegate.centerX != centerX || oldDelegate.centerY != centerY;
  }
}
