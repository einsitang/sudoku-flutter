import 'package:sudoku/ml/predictor.dart';
import 'package:sudoku/ml/yolov8/yolov8_detector.dart';
import 'package:sudoku/ml/yolov8/yolov8_input.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';

class DetectorFactory {
  static Predictor<YoloV8Input, YoloV8Output>? _sudokuDetector;
  static Predictor<YoloV8Input, YoloV8Output>? _digitsDetector;

  static const int imgSize = 640;

  static const String sudokuModelPath =
      "assets/tf_model/sudoku/sudoku_float16.tflite";
  // "assets/tf_model/sudoku/sudoku_full_integer_quant.tflite";
  static const String sudokuModelMetadataPath =
      "assets/tf_model/sudoku/metadata.yaml";

  static const String digitsModelPath =
      "assets/tf_model/digits/digits_float16.tflite";
  // "assets/tf_model/digits/digits_full_integer_quant.tflite";
  static const String digitsModelMetadataPath =
      "assets/tf_model/digits/metadata.yaml";

  static Future<Predictor<YoloV8Input, YoloV8Output>>
      getSudokuDetector() async {
    _sudokuDetector ??= await YoloV8Detector.load(
      imgsz: (imgSize, imgSize),
      modelPath: sudokuModelPath,
      metadataPath: sudokuModelMetadataPath,
      confThreshold: 0.75,
      enableInt8Quantize: false,
    );
    return _sudokuDetector!;
  }

  static Future<Predictor<YoloV8Input, YoloV8Output>>
      getDigitsDetector() async {
    _digitsDetector ??= await YoloV8Detector.load(
      imgsz: (imgSize, imgSize),
      modelPath: digitsModelPath,
      metadataPath: digitsModelMetadataPath,
      confThreshold: 0.45,
      iouThreshold: 0.45,
      enableInt8Quantize: false,
    );
    return _digitsDetector!;
  }
}
