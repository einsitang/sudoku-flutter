import 'package:sudoku/ml/predictor.dart';

/// YoloV8 Output
///
class YoloV8Output extends Output {
  /**
   * 检测列表
   */
  final List<YoloV8DetectionBox> boxes;

  /**
   * 预处理耗时 ms
   */
  final double preprocessTimes;

  /**
   * 后处理耗时 ms
   */
  final double postprocessTimes;

  /**
   * 推理耗时 ms
   */
  final double inferenceTimes;

  YoloV8Output({
    required this.preprocessTimes,
    required this.postprocessTimes,
    required this.inferenceTimes,
    required this.boxes,
  });

  @override
  String toString() {
    return 'YoloV8Output{boxes_count: ${boxes.length}, preprocessTimes: $preprocessTimes ms, inferenceTimes: $inferenceTimes ms, postprocessTimes: $postprocessTimes ms}';
  }
}

class YoloV8DetectionBox {
  final int classId;
  final String className;
  final double confidence;
  final double x, y, w, h;

  YoloV8DetectionBox({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  @override
  String toString() {
    return 'YoloV8DetectionBox{classId: $classId, className: $className, confidence: $confidence, x: $x, y: $y, w: $w, h: $h}';
  }
}
