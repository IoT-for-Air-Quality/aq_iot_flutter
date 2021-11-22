import 'package:flutter/material.dart';

class MyPoints extends CustomPainter {
  final double max;
  final double min;
  final double value;

  MyPoints(this.max, this.min, this.value);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = Color.lerp(
        Colors.greenAccent, Colors.redAccent, (value - min) / (max - min))!;

    canvas.drawCircle(Offset(10, 10), 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
