import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:sudoku/page/ai_detect_paint.dart';
import 'package:sudoku/util/image_util.dart';

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
                      : Text("请对准数独拍照进行识别",
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

            // show loading indicator
            setState(() {
              _isPredicting = true;
            });

            var sudokuPredictor = await DetectorFactory.getSudokuDetector();
            var digitsPredictor = await DetectorFactory.getDigitsDetector();

            // 静态图片用于测试推理结果 - static image is using on test predict result
            // String imagePath = "assets/image/10.png";
            // var imgByteData = await rootBundle.load(imagePath);
            // var imgBuffData = imgByteData.buffer.asUint8List();
            // ui.Image uiImage = await decodeImageFromList(imgBuffData);

            // 数独检测 , 此处需要补充对图片进行剪切处理,降低图片尺寸也许可以加快推理时间？
            final image = await _controller.takePicture();
            final imgBuffData =  await image.readAsBytes();
            ui.Image uiImage = await decodeImageFromList(imgBuffData);
            var input = YoloV8Input.readImgBytes(imgBuffData);
            YoloV8Output sudokuOutput = sudokuPredictor.predict(input);

            final uiShowImg,showImgBuffData,detectOutput;

            if(sudokuOutput.boxes.isNotEmpty){
              final box = sudokuOutput.boxes[0];
              final x = box.x;
              final y = box.y;
              final w = box.w;
              final h = box.h;
              // crop sudoku part of image
              final cropImg = img.copyCrop(
                await ImageUtil.convertFlutterUiToImage(uiImage),
                x: x.toInt(),
                y: y.toInt(),
                width: w.toInt(),
                height: h.toInt(),
              );


              final uiCropImg = await ImageUtil.convertImageToFlutterUi(cropImg);
              final cropImgBufData = img.encodeJpg(cropImg).buffer.asUint8List();
              YoloV8Output digitsOutput = digitsPredictor.predict(YoloV8Input.readImgBytes(cropImgBufData));

              uiShowImg = uiCropImg;
              showImgBuffData = cropImgBufData;
              detectOutput = digitsOutput;
            }else{
              uiShowImg = uiImage;
              showImgBuffData = imgBuffData;
              detectOutput = sudokuOutput;
            }

            // disable loading indicator
            setState(() {
              _isPredicting = false;
            });

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AIDetectPaintPage(
                    image: uiShowImg, imageData: showImgBuffData, output: detectOutput),
              ),
            );
          } catch (e) {
            log.e(e.toString());
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
