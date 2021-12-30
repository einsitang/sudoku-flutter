import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//import 'package:opencv/opencv.dart';

class ScannerScreenPage extends StatefulWidget {
  final CameraDescription camera;

  const ScannerScreenPage({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  _ScannerScreenPageState createState() => _ScannerScreenPageState();
}

class _ScannerScreenPageState extends State<ScannerScreenPage> {
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;
  ImageProvider _image;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    _initializeControllerFuture.then((_) {
      if (!mounted) {
        return;
      }

      _cameraController.startImageStream((CameraImage availableImage) async {
        List<Plane> list = availableImage.planes;
        setState(() {
          _image = MemoryImage(_concatenatePlanes(list));
        });
//        Uint8List byteData = list[0].bytes;
//        var memoryImg = await ImgProc.canny(byteData, 0, 1);
//        setState(() {
//          _image = MemoryImage(memoryImg);
//        });
      });
    });

    Widget bodyWidget = Container(
        child: Column(children: [
      Expanded(flex: 4, child: CameraPreview(_cameraController)),
      Expanded(
          flex: 4,
          child: _image == null
              ? Text("loading", style: TextStyle(color: Colors.white))
              : Image(image: _image)),
      Expanded(flex: 1, child: Container(color: Colors.black))
    ]));

    Widget scaffold = Scaffold(
        body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return bodyWidget;
              } else {
                // Otherwise, display a loading indicator.
                return Center(child: CircularProgressIndicator());
              }
            }));
    return GestureDetector(
        child: scaffold,
        onDoubleTap: () {
          Navigator.pop(context);
        });
  }
}
