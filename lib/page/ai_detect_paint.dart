import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';

Logger log = Logger();

class AIDetectPaintPage extends StatelessWidget {
  final ui.Image image;
  final Uint8List imageData;
  final YoloV8Output output;

  const AIDetectPaintPage(
      {required this.image, required this.imageData, required this.output});

  Future<img.Image> convertFlutterUiToImage(ui.Image uiImage) async {
    final uiBytes = await uiImage.toByteData();

    final image = img.Image.fromBytes(
        width: uiImage.width,
        height: uiImage.height,
        bytes: uiBytes!.buffer,
        numChannels: 4);

    return image;
  }

  Future<ui.Image> convertImageToFlutterUi(img.Image image) async {
    if (image.format != img.Format.uint8 || image.numChannels != 4) {
      final cmd = img.Command()
        ..image(image)
        ..convert(format: img.Format.uint8, numChannels: 4);
      final rgba8 = await cmd.getImageThread();
      if (rgba8 != null) {
        image = rgba8;
      }
    }

    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

    ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
        height: image.height,
        width: image.width,
        pixelFormat: ui.PixelFormat.rgba8888);

    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);

    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image uiImage = fi.image;

    return uiImage;
  }

  @override
  Widget build(BuildContext context) {
    _init() async {
      // device screen size
      final screenSize = MediaQuery.of(context).size;
      final screenWidth = screenSize.width.toInt();
      final screenHeight = screenSize.height.toInt();

      // origin image size
      final originImageWidth = image.width;
      final originImageHeight = image.height;

      final uiBytes = await image.toByteData();

      final resizeImg = img.copyResize(
        img.Image.fromBytes(
          bytes: uiBytes!.buffer,
          width: originImageWidth,
          height: originImageHeight,
          numChannels: 4,
        ),
        width: screenWidth,
        height: screenHeight,
      );

      final uiResizeImg = await convertImageToFlutterUi(resizeImg);

      // resize image to device screen size
      // final codec = await ui.instantiateImageCodec(imageData,
      //     targetWidth: screenWidth, targetHeight: screenHeight);
      // final resizeImg = (await codec.getNextFrame()).image;

      // 取 detectionBoxes 计算 并截取 sudoku 图像区域
      if (output.boxes.isEmpty) {
        return (
          (screenWidth, screenHeight),
          (originImageWidth, originImageHeight),
          uiResizeImg,
          uiResizeImg
        );
      }

      final widthScale = screenWidth / originImageWidth;
      final heightScale = screenHeight / originImageHeight;

      // final resizeImgBuffer = (await resizeImg.toByteData())!.buffer;

      final box = output.boxes[0];
      double x = box.x;
      double y = box.y;
      double w = box.w;
      double h = box.h;

      final cropImg = img.copyCrop(
        await convertFlutterUiToImage(image),
        x: x.toInt(),
        y: y.toInt(),
        width: w.toInt(),
        height: h.toInt(),
      );

      Uint8List cropImgBytes = img.encodeJpg(cropImg);
      final uiCropImg = await convertImageToFlutterUi(cropImg);

      // 使用 digits model 进行数独检测
      // final digitsDetector = await DetectorFactory.getDigitsDetector();
      //
      // final String customImgPath = "assets/image/10.png";
      // final customImgBytes = await rootBundle.load(customImgPath);
      //
      // YoloV8Output digitsOutput =
      //     digitsDetector.predict(YoloV8Input.readImgBytes(customImgBytes.buffer.asUint8List()));

      // log.d(digitsOutput);
      // 计算行列

      return (
        (screenWidth, screenHeight),
        (originImageWidth, originImageHeight),
        uiResizeImg,
        uiCropImg,
      );
    }

    return FutureBuilder<((int, int), (int, int), ui.Image, ui.Image)>(
        future: _init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.error != null) {
              log.e(snapshot.error);
            }
            final (
              (screenWidth, screenHeight),
              (originImageWidth, originImageHeight),
              resizeImage,
              sudokuImg,
            ) = snapshot.requireData;
            final widthScale = screenWidth / originImageWidth;
            final heightScale = screenHeight / originImageHeight;

            final String centerMessage;
            if (output.boxes.isEmpty) {
              centerMessage = "No Detected";
            } else {
              centerMessage = "Detected Boxes : ${output.boxes.length}";
              // digits detect
              final box = output.boxes[0];
              final x = box.x * widthScale;
              final y = box.y * heightScale;
              final w = box.w * widthScale;
              final h = box.h * heightScale;
            }

            return CustomPaint(
              child: Center(
                  child: Text(
                centerMessage,
                style: TextStyle(fontSize: 20, color: Colors.blue),
              )),
              painter: _BackgroundPainter(resizeImage),
              foregroundPainter: _ForegroundPainter(
                output: output,
                widthScale: widthScale,
                heightScale: heightScale,
              ),
            );
          }

          return Center(child: CircularProgressIndicator());
        });
  }
}

class _ForegroundPainter extends CustomPainter {
  final YoloV8Output output;
  final double widthScale;
  final double heightScale;

  const _ForegroundPainter(
      {required this.output,
      required this.widthScale,
      required this.heightScale});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var paint = ui.Paint()
      ..color = Colors.red
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    output.boxes.forEach((box) {
      double x, y, w, h;
      x = (box.x < 0 ? 0 : box.x) * widthScale;
      y = (box.y < 0 ? 0 : box.y) * heightScale;
      w = box.w * widthScale;
      h = box.h * heightScale;

      canvas.drawRect(ui.Rect.fromLTWH(x, y, w, h), paint);
      TextPainter(
        text: TextSpan(
          text: box.className,
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 30,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(x, y));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _BackgroundPainter extends CustomPainter {
  final ui.Image image;

  const _BackgroundPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    ui.Offset offset = ui.Offset(0, 0);
    var paint = Paint();
    canvas.drawImage(image, offset, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
