import 'dart:math';

import 'package:dart_tensor/dart_tensor.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:sudoku/ml/predictor.dart';
import 'package:sudoku/ml/yolov8/yolov8_input.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:yaml/yaml.dart';

Logger log = Logger();

class YoloV8Detector extends Predictor<YoloV8Input, YoloV8Output> {
  final (int, int) imgsz;
  final String modelPath;
  final String metadataPath;
  final double confThreshold;
  final double iouThreshold;
  late final Interpreter interpreter;
  late final YamlMap classes;

  YoloV8Detector._internal({
    required this.interpreter,
    required this.classes,
    required this.imgsz,
    required this.modelPath,
    required this.metadataPath,
    required this.confThreshold,
    required this.iouThreshold,
  });

  static Future<YoloV8Detector> load({
    required (int, int) imgsz,
    required String modelPath,
    required String metadataPath,
    double confThreshold = 0.5,
    double iouThreshold = 0.45,
  }) async {
    final options = InterpreterOptions()..addDelegate(GpuDelegateV2());
    var interpreter = await Interpreter.fromAsset(modelPath, options: options);

    String yamlContent = await rootBundle.loadString(metadataPath);
    var metadata = loadYaml(yamlContent);
    var classes = metadata['names'];

    return YoloV8Detector._internal(
        interpreter: interpreter,
        classes: classes,
        imgsz: imgsz,
        modelPath: modelPath,
        metadataPath: metadataPath,
        confThreshold: confThreshold,
        iouThreshold: iouThreshold);
  }

  preprocess(YoloV8Input input) {
    int IMG_WIDTH = this.imgsz.$1;
    int IMG_HEIGHT = this.imgsz.$2;

    cv.Mat originImgMat = input.mat;
    var oWidth = originImgMat.width;
    var oHeight = originImgMat.height;
    var length = oWidth > oHeight ? oWidth : oHeight;

    var dx = (length - oWidth) ~/ 2;
    var dy = (length - oHeight) ~/ 2;
    cv.Mat scaleImgMat = cv.copyMakeBorder(
        originImgMat, dy, dy, dx, dx, cv.BORDER_CONSTANT,
        value: cv.Scalar(114, 114, 114, 0));

    var blobMat = cv.blobFromImage(scaleImgMat,
        scalefactor: 1 / 255,
        size: (IMG_WIDTH, IMG_HEIGHT),
        swapRB: true,
        ddepth: cv.MatType.CV_32F);

    // CHW tp HWC
    cv.Mat hwcMat = _chw2hwc(blobMat);

    return hwcMat.data.buffer.asFloat32List();
  }

  postprocess(List output, {required int oHeight, required int oWidth}) {
    var arr = output[0];

    DartTensor dt = DartTensor();
    arr = dt.linalg.transpose(arr);

    List<cv.Rect> boxes = [];
    List<(double, double, double, double)> boxValues = [];
    List<double> scores = [];
    List<int> classIds = [];

    int IMG_WIDTH = this.imgsz.$1;
    int IMG_HEIGHT = this.imgsz.$2;

    var gain = min(IMG_HEIGHT / oHeight, IMG_WIDTH / oWidth);
    var pad = (
      ((IMG_WIDTH - oWidth * gain) / 2 - 0.1).round(),
      ((IMG_HEIGHT - oHeight * gain) / 2 - 0.1).round()
    );

    for (List item in arr) {
      List confs = item.sublist(4);
      var confsMat =
          cv.Mat.fromList(1, 1, cv.MatType.CV_32FC1, List<double>.from(confs));
      var (_, maxScore, _, maxClassLoc) = cv.minMaxLoc(confsMat);

      // filter lower then confThreshold may skip same epochs
      if (maxScore < confThreshold) {
        continue;
      }

      double x = (item[0] - (0.5 * item[2]));
      double y = (item[1] - (0.5 * item[3]));
      double w = item[2];
      double h = item[3];

      boxes.add(cv.Rect(x.toInt(), y.toInt(), w.toInt(), h.toInt()));
      scores.add(maxScore);
      classIds.add(maxClassLoc.y);

      x = (x.toInt() - pad.$1) / gain;
      y = (y.toInt() - pad.$2) / gain;
      w = w.toInt() / gain;
      h = h.toInt() / gain;
      boxValues.add((x, y, w, h));
    }

    var indicesList = cv.NMSBoxes(cv.VecRect.fromList(boxes),
        cv.VecF32.fromList(scores), this.confThreshold, this.iouThreshold);

    List<YoloV8DetectionBox> detectionBoxes = [];
    for (var index in indicesList) {
      var (x, y, w, h) = boxValues[index];
      var classId = classIds[index];
      detectionBoxes.add(YoloV8DetectionBox(
        classId: classId,
        className: classes[classId] ??= 'Unknow',
        confidence: scores[index],
        x: x,
        y: y,
        w: w,
        h: h,
      ));
    }

    return detectionBoxes;
  }

  /**
   * CHW to HWC
   */
  _chw2hwc(cv.Mat mat) {
    final size = mat.size;

    final c = size[1];
    final h = size[2];
    final w = size[3];
    cv.Mat chw = mat.reshapeTo(0, [c, h * w]);
    return chw.transpose();
  }

  _predict(YoloV8Input input) {
    Tensor inputTensor = interpreter.getInputTensor(0);
    Tensor outputTensor = interpreter.getOutputTensor(0);

    var output = ListShape(
            List<int>.filled(outputTensor.shape.reduce((v, c) => v * c), 0))
        .reshape(outputTensor.shape);

    DateTime preprocessBegin = DateTime.now();
    var _input = ListShape(preprocess(input)).reshape(inputTensor.shape);
    DateTime inferenceBegin = DateTime.now();
    this.interpreter.run(_input, output);
    DateTime postprocessBegin = DateTime.now();
    List<YoloV8DetectionBox> boxes =
        postprocess(output, oHeight: input.mat.height, oWidth: input.mat.width);
    DateTime postprocessEnd = DateTime.now();

    var preprocessTimes = (inferenceBegin.microsecondsSinceEpoch -
            preprocessBegin.microsecondsSinceEpoch) /
        1000;
    var postprocessTimes = (postprocessEnd.microsecondsSinceEpoch -
        postprocessBegin.microsecondsSinceEpoch) /
        1000;
    var inferenceTimes = (postprocessBegin.microsecondsSinceEpoch -
            inferenceBegin.microsecondsSinceEpoch) /
        1000;

    log.d("preprocessTimes:$preprocessTimes ms, postprocessTimes: $postprocessTimes ms, inferenceTimes: $inferenceTimes ms");

    return YoloV8Output(
        preprocessTimes: preprocessTimes,
        postprocessTimes: postprocessTimes,
        inferenceTimes: inferenceTimes,
        boxes: boxes);
  }

  @override
  YoloV8Output predict(YoloV8Input input) {
    return _predict(input);
  }
}
