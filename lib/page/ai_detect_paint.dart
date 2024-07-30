import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';

Logger log = Logger();

class AIDetectPaintPage extends StatelessWidget {
  final ui.Image image;
  final Uint8List imageData;
  final YoloV8Output output;

  const AIDetectPaintPage(
      {required this.image, required this.imageData, required this.output});

  @override
  Widget build(BuildContext context) {
    _resize() async {
      // device screen size
      final screenSize = MediaQuery.of(context).size;
      final screenWidth = screenSize.width.toInt();
      final screenHeight = screenSize.height.toInt();

      // origin image size
      final originImageWidth = image.width;
      final originImageHeight = image.height;

      // resize image to device screen size
      final codec = await ui.instantiateImageCodec(imageData,
          targetWidth: screenWidth, targetHeight: screenHeight);
      final resizeImage = (await codec.getNextFrame()).image;

      return (
        (screenWidth, screenHeight),
        (originImageWidth, originImageHeight),
        resizeImage
      );
    }

    return FutureBuilder<((int, int), (int, int), ui.Image)>(
        future: _resize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final (
              (screenWidth, screenHeight),
              (originImageWidth, originImageHeight),
              resizeImage
            ) = snapshot.requireData;
            final widthScale = screenWidth / originImageWidth;
            final heightScale = screenHeight / originImageHeight;

            String centerMessage = "Sudoku Puzzle Testing";
            if (output.boxes.isEmpty) {
              centerMessage = "No Sudoku Puzzle Detected";
            }

            return CustomPaint(
              child: Center(
                  child: Text(
                centerMessage,
                style: TextStyle(fontSize: 20, color: Colors.white),
              )),
              painter: _BackgroundPainter(resizeImage),
              foregroundPainter: _ForegroundPainter(
                output: output,
                widthScale: widthScale,
                heightScale: heightScale,
              ),
            );
          }

          return Center(child: CircularProgressIndicator());
        });
  }
}

class _ForegroundPainter extends CustomPainter {
  final YoloV8Output output;
  final double widthScale;
  final double heightScale;

  const _ForegroundPainter(
      {required this.output,
      required this.widthScale,
      required this.heightScale});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var paint = ui.Paint()
      ..color = Colors.red
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    output.boxes.forEach((box) {
      canvas.drawRect(
          ui.Rect.fromLTWH(
            box.x * widthScale,
            box.y * heightScale,
            box.w * widthScale,
            box.h * heightScale,
          ),
          paint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _BackgroundPainter extends CustomPainter {
  final ui.Image image;

  const _BackgroundPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    ui.Offset offset = ui.Offset(0, 0);
    var paint = Paint();
    log.d("size (${size.width},${size.height})");
    canvas.drawImage(image, offset, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
