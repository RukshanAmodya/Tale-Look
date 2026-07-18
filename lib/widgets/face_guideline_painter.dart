import 'package:flutter/material.dart';

class FaceGuidelinePainter extends CustomPainter {
  final double centerX;
  final double centerY;

  FaceGuidelinePainter({required this.centerX, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final paintCircle = Paint()
      ..color = const Color(0xFFFF9000).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintDotted = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final shortestSide = size.shortestSide;
    
    final centerOffset = Offset(size.width * centerX, size.height * centerY);
    final width = shortestSide * 0.72;
    final height = shortestSide * 0.88;
    
    final rect = Rect.fromCenter(
      center: centerOffset,
      width: width,
      height: height,
    );
    canvas.drawOval(rect, paintCircle);
    
    // Draw horizontal dashed "EYE LINE"
    double lineY = centerOffset.dy;
    double startX = centerOffset.dx - (width / 2);
    double endX = centerOffset.dx + (width / 2);
    
    double currentX = startX;
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, lineY),
        Offset(currentX + 6, lineY),
        paintDotted,
      );
      currentX += 12;
    }

    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final leftArrow = Path()
      ..moveTo(startX, lineY)
      ..lineTo(startX + 6, lineY - 4)
      ..lineTo(startX + 6, lineY + 4)
      ..close();
    canvas.drawPath(leftArrow, arrowPaint);

    final rightArrow = Path()
      ..moveTo(endX, lineY)
      ..lineTo(endX - 6, lineY - 4)
      ..lineTo(endX - 6, lineY + 4)
      ..close();
    canvas.drawPath(rightArrow, arrowPaint);

    const textStyleLabel = TextStyle(
      color: Colors.white60,
      fontSize: 8,
      fontWeight: FontWeight.bold,
    );
    final textPainterLabel = TextPainter(
      text: const TextSpan(text: 'EYE LINE', style: textStyleLabel),
      textDirection: TextDirection.ltr,
    );
    textPainterLabel.layout();
    textPainterLabel.paint(
      canvas, 
      Offset(startX + 10, lineY - 12),
    );

    final boxPaint = Paint()
      ..color = const Color(0xFFFF9000)
      ..style = PaintingStyle.fill;

    double boxWidth = 32;
    double boxHeight = 16;
    double boxY = centerOffset.dy + (height / 2) - (boxHeight / 2);
    
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerOffset.dx, boxY),
        width: boxWidth,
        height: boxHeight,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, boxPaint);

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );
    final textPainter = TextPainter(
      text: const TextSpan(text: '-18°', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(centerOffset.dx - (textPainter.width / 2), boxY - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant FaceGuidelinePainter oldDelegate) {
    return oldDelegate.centerX != centerX || oldDelegate.centerY != centerY;
  }
}
