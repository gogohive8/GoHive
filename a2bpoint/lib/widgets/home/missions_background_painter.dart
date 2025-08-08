// widgets/home/missions_background_painter.dart
import 'package:flutter/material.dart';

class MissionsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4F3EE);
    final radius = 32.0;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0),
          radius: Radius.circular(radius), clockwise: false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}