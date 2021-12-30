// ⚠️ opencv link test page , do not publish release

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/ffi/native_opencv.dart';
import 'package:path_provider/path_provider.dart';

class OpenCVTestPage extends StatefulWidget {
  const OpenCVTestPage({Key key}) : super(key: key);

  @override
  _OpenCVTestPageState createState() => _OpenCVTestPageState();
}

Logger logger = Logger();

class _OpenCVTestPageState extends State<OpenCVTestPage> {
  Directory tempDir;

  String get tempPath => '${tempDir.path}/temp.jpg';

  bool _isProcessed = false;
  bool _isWorking = false;
  Uint8List _pic;

  Future<void> takeImageAndProcess() async {
    logger.d("takeImageAndProcess enter");
    PickedFile image = await ImagePicker()
        .getImage(source: ImageSource.gallery, imageQuality: 100);

    setState(() {
      _isWorking = true;
    });

    // Creating a port for communication with isolate and arguments for entry point
    final port = ReceivePort();
    final args = ProcessImageArguments(image.path, tempPath);

    Uint8List imgByte = await image.readAsBytes();

    logger.d("Isolate begin");

    // Spawning an isolate
//    Isolate.spawn<ProcessImageArguments>(
//        processImage,
//        args,
//        onError: port.sendPort,
//        onExit: port.sendPort
//    );

    var isolate =
        Isolate.spawn<dynamic>(processThreshold, [imgByte, port.sendPort]);

    logger.d("Isolate after , wating async function");

    // Making a variable to store a subscription in
    StreamSubscription sub;

    // Listeting for messages on port
//    sub = port.listen((_) async {
//      // Cancel a subscription after message received called
//      await sub?.cancel();
//
//      setState(() {
//        _isProcessed = true;
//        _isWorking = false;
//      });
//    });

    isolate.then((_) => {
          port.listen((data) {
            List<int> imgData = data;
            setState(() {
              _pic = Uint8List.fromList(imgData);
              _isProcessed = true;
              _isWorking = false;
            });
          })
        });
  }

  void processThreshold(dynamic arg) {
    Uint8List imgByte = arg[0];
    SendPort sendPort = arg[1];
    sendPort.send(threshold(imgByte.toList()));
  }

  @override
  Widget build(BuildContext context) {
    getTemporaryDirectory().then((dir) => tempDir = dir);

    return Scaffold(
      appBar: AppBar(title: Text("OpenVC Test")),
      body: Stack(
        children: <Widget>[
          Center(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                if (_isProcessed && !_isWorking)
                  ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: 3000, maxHeight: 300),
                      child: Image(image: MemoryImage(_pic))
//                        Image.file(File(tempPath), alignment: Alignment.center),
                      ),
                Builder(builder: (context) {
                  return RaisedButton(
                      child: Text('Show version : ${opencvVersion()}'));
                }),
                RaisedButton(
                    child: Text('Process photo'),
                    onPressed: takeImageAndProcess)
              ],
            ),
          ),
          if (_isWorking)
            Positioned.fill(
                child: Container(
              color: Colors.black.withOpacity(.7),
              child: Center(child: CircularProgressIndicator()),
            )),
        ],
      ),
    );
  }
}
