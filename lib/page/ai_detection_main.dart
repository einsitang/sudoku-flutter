import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:sudoku/page/ai_detection_painter.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

Logger log = Logger();

/// just define magic -1 to SUDOKU_EMPTY_DIGIT , make code easier to read and know
const int SUDOKU_EMPTY_DIGIT = -1;

/// Detect Ref
///
///
class DetectRef {
  /// puzzle index
  final int index;

  /// puzzle value of index
  final int value;

  /// puzzle value of index from detect box
  final YoloV8DetectionBox box;

  const DetectRef({
    required this.index,
    required this.value,
    required this.box,
  });
}

class AIDetectionMainWidget extends StatefulWidget {
  final List<DetectRef?> detectRefs;
  final ui.Image image;
  final Uint8List imageBytes;
  final double widthScale;
  final double heightScale;
  final YoloV8Output output;

  const AIDetectionMainWidget({
    Key? key,
    required this.detectRefs,
    required this.image,
    required this.imageBytes,
    required this.widthScale,
    required this.heightScale,
    required this.output,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AIDetectionMainWidgetState();
}

class _AIDetectionMainWidgetState extends State<AIDetectionMainWidget> {

  /// amendable cell edit on this "amendPuzzle"
  ///
  /// when amendPuzzle[index] != SUDOKU_EMPTY_DIGIT (-1) , grid cell of index will show value with blue color text
  late List<int> amendPuzzle;

  late List<int> solution;
  late String solveMessage;
  int? selectedBox = null;

  @override
  void initState() {
    super.initState();

    amendPuzzle = _emptyMatrix();
    solution = _emptyMatrix();
    solveMessage = "";
  }

  _emptyMatrix() {
    return List.generate(81, (_) => SUDOKU_EMPTY_DIGIT);
  }

  _solveSudoku() {
    log.d("solve sudoku puzzle");
    try {
      // merge puzzle from detectRefs and amendPuzzle
      final List<int> puzzle = _emptyMatrix();
      for (var index = 0; index < puzzle.length; ++index) {
        DetectRef? detectRef = widget.detectRefs[index];
        if (amendPuzzle[index] != SUDOKU_EMPTY_DIGIT) {
          puzzle[index] = amendPuzzle[index];
        } else if (detectRef != null && detectRef.value != SUDOKU_EMPTY_DIGIT) {
          puzzle[index] = detectRef.value;
        }
      }

      final sudoku = Sudoku(puzzle);
      setState(() {
        solution = sudoku.solution;
        solveMessage = "";
      });
    } catch (e) {
      // seem this puzzle can't be solve because is wrong puzzle
      log.e(e);
      if (e.runtimeType == StateError) {
        final errorMessage = (e as StateError).message;
        setState(() {
          solution = _emptyMatrix();
          solveMessage = errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectRefs = widget.detectRefs;
    final uiImage = widget.image;
    final widthScale = widget.widthScale;
    final heightScale = widget.heightScale;
    final output = widget.output;

    // 主画面控件
    var _mainWidget;
    var hasDetectionSudoku = output.boxes.isNotEmpty;

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
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
        itemBuilder: ((BuildContext context, int index) {
          DetectRef? detectRef = detectRefs[index];

          // default cell text/style/border
          var cellTextColor = detectRef != null && detectRef.value != SUDOKU_EMPTY_DIGIT
              ? Colors.yellow
              : Colors.white;
          var cellText = "";
          var cellBorder = Border.all(color: Colors.amber, width: 1.5);

          if (amendPuzzle[index] != SUDOKU_EMPTY_DIGIT) {
            // 修正的谜题
            cellText = amendPuzzle[index].toString();
            cellTextColor = Colors.blue;
          } else if (detectRef != null && detectRef.value != SUDOKU_EMPTY_DIGIT) {
            // 检测关联的谜题
            cellText = detectRef.value.toString();
            cellTextColor = Colors.yellow;
          } else if (solution[index] != SUDOKU_EMPTY_DIGIT) {
            // solutions
            cellText = solution[index].toString();
            cellTextColor = Colors.white;
          }

          if (index == selectedBox) {
            // if choose cell , change the border
            cellBorder = Border.all(color: Colors.blue, width: 2.0);
          }

          var _cellContainer = Container(
            decoration: BoxDecoration(
              border: cellBorder,
            ),
            child: Text(
              cellText,
              style: TextStyle(
                  shadows: [ui.Shadow(blurRadius: 3.68)],
                  fontSize: 30,
                  color: cellTextColor),
            ),
          );

          return InkWell(
            child: _cellContainer,
            onTap: () {
              setState(() {
                if (selectedBox == null) {
                  selectedBox = index;
                } else if (selectedBox == index) {
                  selectedBox = null;
                } else {
                  selectedBox = index;

                  // @TODO here should show dialog to input amend value from user
                }
              });
            },
          );
        }),
      );

      _mainWidget = _gridWidget;
    }

    var _drawWidget = CustomPaint(
      child: _mainWidget,
      painter: AIDetectionPainter(
        image: uiImage,
        output: output,
        offset: ui.Offset(0, 0),
        widthScale: widthScale,
        heightScale: heightScale,
      ),
    );

    var _btnWidget = Offstage(
      offstage: !hasDetectionSudoku,
      child: IconButton(
        icon: Icon(Icons.visibility),
        iconSize: 36,
        onPressed: _solveSudoku,
      ),
    );

    var _bodyWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // show solve message output
        Center(
          child: Text(
            solveMessage,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
        Center(
          child: SizedBox(
              width: uiImage.width.toDouble(),
              height: uiImage.height.toDouble(),
              child: _drawWidget),
        ),
        Center(child: _btnWidget),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text("Detection Result")),
      body: _bodyWidget,
    );
  }
}
