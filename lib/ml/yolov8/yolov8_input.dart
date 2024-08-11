import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:sudoku/ml/predictor.dart';

/// YoloV8 Input
///
class YoloV8Input extends Input {
  final cv.Mat _mat;

  YoloV8Input._internal(this._mat);

  cv.Mat get mat => this._mat;

  static readImg(String path) async {
    return YoloV8Input._internal(cv.imread(path));
  }

  static readImgBytes(Uint8List bytes) {
    return YoloV8Input._internal(cv.imdecode(bytes, cv.IMREAD_COLOR));
  }
}
