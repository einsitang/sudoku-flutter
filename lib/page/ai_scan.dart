import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/page/ai_detect_paint.dart';

import '../ml/detector.dart';
import '../ml/yolov8/yolov8_input.dart';
import '../ml/yolov8/yolov8_output.dart';

final Logger log = Logger();

class AIScanPage extends StatefulWidget {
  const AIScanPage({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  AIScanPageState createState() => AIScanPageState();
}

class AIScanPageState extends State<AIScanPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool _isPredicting = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.

            return LayoutBuilder(
              builder: (context, constraints) {
                var _cameraWidget = SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CameraPreview(_controller),
                );

                var _centerWidget = Center(
                  child: _isPredicting
                      ? CircularProgressIndicator()
                      : Text("请对准数独进行识别",
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                );

                // 罩层 Overlay
                var _max = max(constraints.maxWidth, constraints.maxHeight);
                var _min = min(constraints.maxWidth, constraints.maxHeight);
                var _m = _max - _min;
                _m = _m * 1.2 / 2;

                var longBorderSide =
                    BorderSide(color: Color.fromRGBO(0, 0, 0, 0.8), width: _m);
                var shortBorderSide = BorderSide(
                    color: Color.fromRGBO(0, 0, 0, 0.8), width: _m / 3);

                var _overlayWidget = Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        top: constraints.maxHeight > constraints.maxWidth
                            ? longBorderSide
                            : shortBorderSide,
                        bottom: constraints.maxHeight > constraints.maxWidth
                            ? longBorderSide
                            : shortBorderSide,
                        left: constraints.maxHeight > constraints.maxWidth
                            ? shortBorderSide
                            : longBorderSide,
                        right: constraints.maxHeight > constraints.maxWidth
                            ? shortBorderSide
                            : longBorderSide,
                      ),
                    ));

                return Stack(
                    children: [_cameraWidget, _centerWidget, _overlayWidget]);
              },
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            if (!context.mounted) {
              return;
            }

            // change state to show loading indicator
            setState(() {
              _isPredicting = true;
            });

            var sudokuPredictor = await DetectorFactory.getSudokuDetector();
            await DetectorFactory.getDigitsDetector(); // preloading , next step will use digits detector to predict sudoku box numbers

            // 静态图片用于测试推理结果 - static image is using on test predict result
            // String imagePath = "assets/image/4.jpg";
            // var imgBytes = await rootBundle.load(imagePath);
            // var byteData = imgBytes.buffer.asUint8List();

            final image = await _controller.takePicture();
            final byteData = await image.readAsBytes();
            var input = YoloV8Input.readImgBytes(byteData);
            YoloV8Output output = sudokuPredictor.predict(input);

            // disable loading indicator
            setState(() {
              _isPredicting = false;
            });

            ui.Image uiImage = await decodeImageFromList(byteData);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AIDetectPaintPage(
                    image: uiImage, imageData: byteData, output: output),
              ),
            );
          } catch (e) {
            log.e(e.toString(), e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
