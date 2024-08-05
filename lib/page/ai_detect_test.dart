import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/ml/yolov8/yolov8_input.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:sudoku/page/ai_detect_paint.dart';

import '../ml/detector.dart';

Logger log = Logger();

class AIDetectTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _init() async {
      // sudoku model
      var sudokuPredictor = await DetectorFactory.getSudokuDetector();
      // digits model
      var digitsPredictor = await DetectorFactory.getDigitsDetector();
      // yolov8 official model
      var yolov8nPredictor = await DetectorFactory.getYolov8nDetector();

      // 6.png is image of sudoku , use digits model to detect
      // final String imgPath = "assets/image/6.png";

      // bus.jpg is from yolo official demo image , you can use yolov8n to detect
      final String imgPath = "assets/image/bus.jpg";
      final byteData = await rootBundle.load(imgPath);
      final bytes = byteData.buffer.asUint8List();
      YoloV8Output output;
      // output = sudokuPredictor.predict(YoloV8Input.readImgBytes(bytes));
      // output = digitsPredictor.predict(YoloV8Input.readImgBytes(bytes));
      output = yolov8nPredictor.predict(YoloV8Input.readImgBytes(bytes));
      ui.Image uiImage = await decodeImageFromList(bytes);

      var aiDetectPainPage = AIDetectPaintPage(
          image: uiImage,
          imageData: byteData.buffer.asUint8List(),
          output: output);

      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => aiDetectPainPage));

    }

    return FutureBuilder(
        future: _init(),
        builder: (context, snapshot) {
          if(snapshot.hasError){
            log.e(snapshot.error);
            log.e(snapshot.stackTrace);
          }
          return Text("work done , see console");
        });
  }
}
