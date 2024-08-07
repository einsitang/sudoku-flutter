import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:sudoku/page/ai_detection_painter.dart';
import 'package:sudoku/util/image_util.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

Logger log = Logger();

class AIDetectPaintPage extends StatefulWidget {
  final ui.Image image;
  final Uint8List imageBytes;
  final YoloV8Output output;

  const AIDetectPaintPage({
    required this.image,
    required this.imageBytes,
    required this.output,
  });

  @override
  _AIDetectPainPageState createState() => _AIDetectPainPageState();
}

class _AIDetectPainPageState extends State<AIDetectPaintPage> {
  var detectPuzzles;
  var detectSolution;

  @override
  void initState() {
    super.initState();
    // 初始化检测 puzzle and solution
    detectPuzzles = List.generate(81, (index) => -1);
    detectSolution = List.generate(81, (index) => -1);
  }

  @override
  Widget build(BuildContext context) {
    _init() async {
      // device screen size
      final screenSize = MediaQuery.of(context).size;
      final screenWidth = screenSize.width.toInt();
      final screenHeight = screenSize.height.toInt();

      // origin image size
      final originImageWidth = widget.image.width;
      final originImageHeight = widget.image.height;

      final uiBytes = await widget.image.toByteData();

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
      final hasDetectionSudoku = widget.output.boxes.isNotEmpty;

      if (hasDetectionSudoku) {
        // begin calculate sudoku rows and cols
        final boxes = widget.output.boxes;

        // can fixable cells
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
          var index = (rowIndex * 9 + colIndex).toInt();

          detectPuzzles[index] = box.classId;
        });
      }

      return (
        (screenWidth, screenHeight),
        (originImageWidth, originImageHeight),
        (widthScale, heightScale),
        uiResizeImg,
      );
    }

    return FutureBuilder<((int, int), (int, int), (double, double), ui.Image)>(
        future: _init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.error != null) {
              log.e(snapshot.error);
            }
            final (
              (screenWidth, screenHeight),
              (originImageWidth, originImageHeight),
              (widthScale, heightScale),
              uiResizeImg,
            ) = snapshot.requireData;

            // 主画面控件
            var _mainWidget;
            var hasDetectionSudoku = widget.output.boxes.isNotEmpty;

            if (!hasDetectionSudoku) {
              _mainWidget = const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 128,
                    color: Colors.white,
                    shadows: [ui.Shadow(blurRadius: 1.68)],
                  ),
                  Center(
                    child: Text("Not Detected",
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          shadows: [ui.Shadow(blurRadius: 1.68)],
                        )),
                  ),
                ],
              );
            } else {
              final _gridWidget = GridView.builder(
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: false,
                itemCount: 81,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9),
                itemBuilder: ((BuildContext context, int index) {
                  var cellColor =
                      detectPuzzles[index] != -1 ? Colors.yellow : Colors.white;
                  var cellText = "";
                  if (detectSolution[index] != -1) {
                    cellText = detectSolution[index].toString();
                  }
                  if (detectPuzzles[index] != -1) {
                    cellText = detectPuzzles[index].toString();
                  }
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amberAccent, width: 1.5),
                    ),
                    child: Text(
                      cellText,
                      style: TextStyle(
                          shadows: [ui.Shadow(blurRadius: 1.68)],
                          fontSize: 30,
                          color: cellColor),
                    ),
                  );
                }),
              );

              _mainWidget = _gridWidget;
            }

            var _drawWidget = CustomPaint(
              child: _mainWidget,
              painter: AIDetectionPainter(
                image: uiResizeImg,
                output: widget.output,
                offset: ui.Offset(0, 0),
                widthScale: widthScale,
                heightScale: heightScale,
              ),
            );

            var _btnWidget = Offstage(
              offstage: !hasDetectionSudoku,
              child: TextButton(
                child: Text("解题"),
                onPressed: _solveSudoku,
              ),
            );

            var _bodyWidget = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: SizedBox(
                      width: uiResizeImg.width.toDouble(),
                      height: uiResizeImg.height.toDouble(),
                      child: _drawWidget),
                ),
                Center(child: _btnWidget),
              ],
            );

            return Scaffold(
                appBar: AppBar(title: Text("Detection Result")),
                body: _bodyWidget);
          }

          log.d("loading???");
          return Center(child: CircularProgressIndicator());
        });
  }

  _solveSudoku() async {
    log.d("解题中");
    try {
      var sudoku = Sudoku(detectPuzzles);
      setState(() {
        detectSolution = sudoku.solution;
      });
    } catch (e) {
      log.e(e);
    }
  }
}
