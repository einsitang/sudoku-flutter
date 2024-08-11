import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:sudoku/page/ai_detection_main.dart';
import 'package:sudoku/util/image_util.dart';

Logger log = Logger();

class AIDetectPaintPage extends StatelessWidget {
  final ui.Image image;
  final Uint8List imageBytes;
  final YoloV8Output output;

  const AIDetectPaintPage({
    required this.image,
    required this.imageBytes,
    required this.output,
  });

  @override
  Widget build(BuildContext context) {
    _init() async {
      // device screen size
      final screenSize = MediaQuery.of(context).size;
      final screenWidth = screenSize.width.toInt();
      final screenHeight = screenSize.height.toInt();

      // origin image size
      final originImageWidth = image.width;
      final originImageHeight = image.height;

      final uiBytes = await image.toByteData();

      final _min = min(screenWidth, screenHeight);
      final widthScale = 0.9 * _min / originImageWidth;
      final heightScale = 0.9 * _min / originImageHeight;
      final resizeImg = img.copyResize(
        img.Image.fromBytes(
          bytes: uiBytes!.buffer,
          width: originImageWidth,
          height: originImageHeight,
          numChannels: 4,
        ),
        width: (widthScale * originImageWidth).round(),
        height: (heightScale * originImageHeight).round(),
      );
      final uiResizeImg = await ImageUtil.convertImageToFlutterUi(resizeImg);
      final hasDetectionSudoku = output.boxes.isNotEmpty;

      final List<DetectRef?> detectRefs = List.generate(81, (_) => null);
      if (hasDetectionSudoku) {
        // begin calculate sudoku rows and cols
        final boxes = output.boxes;

        // 计算单元格大小
        final colBlock = originImageHeight ~/ 9;
        final rowBlock = originImageWidth ~/ 9;

        final colBlockN = colBlock * 3 / 4;
        final rowBlockN = rowBlock * 3 / 4;

        boxes.forEach((box) {
          // 0 must be a mistake.
          if (box.classId == 0) {
            return;
          }

          var x, y;
          x = box.x.toInt();
          y = box.y.toInt();

          var colIndex = (x ~/ rowBlock) + ((x % rowBlock > rowBlockN) ? 1 : 0);
          var rowIndex = (y ~/ colBlock) + ((y % colBlock > colBlockN) ? 1 : 0);
          int index = (rowIndex * 9 + colIndex).toInt();

          detectRefs[index] = DetectRef(
            index: index,
            value: box.classId,
            box: box,
          );
        });
      }

      return (
        (widthScale, heightScale),
        uiResizeImg,
        detectRefs,
      );
    }

    return FutureBuilder<((double, double), ui.Image, List<DetectRef?>)>(
        future: _init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.error != null) {
              log.e(snapshot.error);
            }
            final (
              (widthScale, heightScale),
              uiResizeImg,
              detectRefs,
            ) = snapshot.requireData;

            return AIDetectionMainWidget(
              detectRefs: detectRefs,
              image: uiResizeImg,
              imageBytes: imageBytes,
              widthScale: widthScale,
              heightScale: heightScale,
              output: output,
            );
          }

          return Center(
            child: CircularProgressIndicator(
              color: Colors.amberAccent,
              backgroundColor: Colors.white,
            ),
          );
        });
  }
}
