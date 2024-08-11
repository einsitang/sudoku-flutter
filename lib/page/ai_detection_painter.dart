import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';

class AIDetectionPainter extends CustomPainter {
  final ui.Image image;
  final YoloV8Output output;
  final double widthScale;
  final double heightScale;
  final ui.Offset offset;

  const AIDetectionPainter({
    required this.image,
    required this.output,
    required this.widthScale,
    required this.heightScale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var imgPaint = Paint();
    imgPaint.color = ui.Color.fromRGBO(128, 128, 128, 0.6);
    canvas.drawImage(image, offset, imgPaint);

    var boxPaint = ui.Paint()
      ..color = Colors.red
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    output.boxes.forEach((box) {
      double x, y, w, h;
      x = (box.x < 0 ? 0 : box.x) * widthScale;
      y = (box.y < 0 ? 0 : box.y) * heightScale;
      w = box.w * widthScale;
      h = box.h * heightScale;

      x = x + offset.dx;
      y = y + offset.dy;

      canvas.drawRect(ui.Rect.fromLTWH(x, y, w, h), boxPaint);

      // 文字绘制
      // TextPainter(
      //   text: TextSpan(
      //     text: box.className,
      //     style: TextStyle(
      //       color: Colors.redAccent,
      //       fontSize: 30,
      //     ),
      //   ),
      //   textDirection: TextDirection.ltr,
      // )
      //   ..layout()
      //   ..paint(canvas, Offset(x, y));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
