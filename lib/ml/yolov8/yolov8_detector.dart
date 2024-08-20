import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
  final String modelPath;
  final String metadataPath;
  final double confThreshold;
  final double iouThreshold;
  final bool enableInt8Quantize;
  final (int, int) imgsz;
  late final Interpreter interpreter;
  late final YamlMap classes;

  YoloV8Detector._internal({
    required this.interpreter,
    required this.classes,
    required this.modelPath,
    required this.metadataPath,
    required this.imgsz,
    required this.confThreshold,
    required this.iouThreshold,
    required this.enableInt8Quantize,
  });

  static Future<YoloV8Detector> load({
    required String modelPath,
    required String metadataPath,
    (int, int) imgsz = (640, 640),
    double confThreshold = 0.5,
    double iouThreshold = 0.45,

    /// int8 quantitative model seem not enough validation,not recommend to use
    @deprecated bool enableInt8Quantize = false,
  }) async {
    var interpreter = await _buildInterpreterFromAsset(modelPath);
    // var interpreter = await Interpreter.fromAsset(modelPath, options: options);

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
      iouThreshold: iouThreshold,
      enableInt8Quantize: enableInt8Quantize,
    );
  }

  preprocess(YoloV8Input input) {
    var (int IMG_WIDTH, int IMG_HEIGHT) = this.imgsz;

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
    return _chw2hwc(blobMat);
  }

  /// 2-d matrix transpose
  List _2dTranspose(List list) {
    List shape = ListShape(list).shape;
    if (shape.length != 2) {
      throw new Exception("only support 2-D Tensor");
    }
    // can not sure type , so try to get first value check runtime type
    var initV = list[0][0].runtimeType == double ? 0.0 : 0;
    shape = shape.reversed.toList(growable: true);
    List toReturn = List.generate(
        shape[0], (index) => List.generate(shape[1], (index) => initV));
    for (int i = 0; i < shape[0]; i++) {
      for (int j = 0; j < shape[1]; j++) {
        toReturn[i][j] = list[j][i];
      }
    }
    return toReturn;
  }

  postprocess(List output, {required int oHeight, required int oWidth}) {
    var arr = output[0];

    arr = _2dTranspose(arr);

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
      var (maxScore, maxClassLoc) = _maxLoc(confs);

      double x = (item[0] - (0.5 * item[2]));
      double y = (item[1] - (0.5 * item[3]));
      double w = item[2];
      double h = item[3];

      boxes.add(cv.Rect(x.toInt(), y.toInt(), w.toInt(), h.toInt()));
      scores.add(maxScore);
      classIds.add(maxClassLoc);

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
        className: classes[classId] ?? 'Unknown',
        confidence: scores[index],
        x: x,
        y: y,
        w: w,
        h: h,
      ));
    }

    return detectionBoxes;
  }

  (double, int) _maxLoc(List list) {
    int loc = 0;
    var v = null;

    for (var (index, item) in list.indexed) {
      if (v == null) {
        v = item;
      }
      if (item > v) {
        v = item;
        loc = index;
      }
    }
    return (v, loc);
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

  /// 预测逻辑流程 - predict logic workflow
  ///
  /// input => preprocess  => _input
  ///
  /// quantization of preprocess (⚠️ INT8 quantization work , but seem not well and need improve , not recommend to use)
  ///
  /// _input => inference => _output
  ///
  /// quantization of postprocess (️⚠️ INT8 quantization work , but seem not well and need improve , not recommend to use)
  ///
  /// _output => postprocess => output
  _predict(YoloV8Input input) {
    Tensor inputTensor = interpreter.getInputTensor(0);
    Tensor outputTensor = interpreter.getOutputTensor(0);

    QuantizationParams inputQuantization = inputTensor.params;
    QuantizationParams outputQuantization = outputTensor.params;

    DateTime preprocessBegin = DateTime.now();

    final cv.Mat _mat = preprocess(input);
    Uint8List _input = _mat.data;
    if (enableInt8Quantize) {
      // INT8 量化预处理
      final _int8Data = _input.buffer
          .asFloat32List()
          .map((e) =>
              (e / inputQuantization.scale + inputQuantization.zeroPoint)
                  .round())
          .toList();
      _input = Uint8List.fromList(_int8Data);
    }

    DateTime inferenceBegin = DateTime.now();

    inputTensor.data = _input;
    this.interpreter.invoke();

    DateTime postprocessBegin = DateTime.now();
    var output;
    var _output = outputTensor.data;
    if (enableInt8Quantize) {
      // INT8量化后处理 INT8 扩充程 FLOAT32
      final _quantOutputData = _output
          .map((e) =>
              ((e - outputQuantization.zeroPoint) * outputQuantization.scale))
          .toList();
      var _float32Output = Float32List.fromList(_quantOutputData);
      output = ListShape(_float32Output).reshape(outputTensor.shape);
    } else {
      output =
          ListShape(_output.buffer.asFloat32List()).reshape(outputTensor.shape);
    }

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

    log.d(
        "preprocessTimes:$preprocessTimes ms, postprocessTimes: $postprocessTimes ms, inferenceTimes: $inferenceTimes ms");

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

  static _buildInterpreterFromAsset(String modelPath) async {
    // default enable GPU
    var interpreter = null;
    final delegates = [];
    if (Platform.isAndroid) {
      delegates.add(GpuDelegateV2());
      delegates.add(XNNPackDelegate());
    } else {
      delegates.add(GpuDelegate());
    }

    // try to use gpu delegate , but didn't know device support delegate
    final delegateIterator = delegates.iterator;
    while (delegateIterator.moveNext()) {
      final gpuDelegate = delegateIterator.current;
      final options = InterpreterOptions()..addDelegate(gpuDelegate);
      try {
        log.i("use gpu delegate: $gpuDelegate");
        interpreter = await Interpreter.fromAsset(modelPath, options: options);
        break;
      } catch (_) {
        // seem not support gpu delegate , change one
        log.w("use gpu delegate: $gpuDelegate failure");
      }
    }

    if (interpreter == null) {
      // interpreter without gpu delegate
      interpreter = await Interpreter.fromAsset(modelPath);
    }

    return interpreter;
  }
}
