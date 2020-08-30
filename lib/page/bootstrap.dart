import 'dart:async';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

final Logger log = Logger();

class BootstrapPage extends StatefulWidget {
  BootstrapPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BootstrapPageState createState() => _BootstrapPageState();
}

Widget _buttonWrapper(
    BuildContext context, Widget childBuilder(BuildContext content)) {
  return Container(
      margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
      width: 300,
      height: 60,
      child: childBuilder(context));
}

Widget _scanButton(BuildContext context) {
  return Offstage(
      offstage: true,
      child: _buttonWrapper(
          context,
          (content) => CupertinoButton(
                color: Colors.blue,
                child: Text("扫独解题"),
                onPressed: () {
                  log.d("scan");
                },
              )));
}

Widget _continueGameButton(BuildContext context) {
  return ScopedModelDescendant<SudokuState>(builder: (context, child, state) {
    return Offstage(
        offstage: state.status != SudokuGameStatus.pause,
        child: Container(
          width: 300,
          height: 80,
          child: CupertinoButton(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      child: Text("继续游戏",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold))),
                  Container(
                      child: Text(
                          '${LEVEL_NAMES[state.level]} - ${state.timer}',
                          style: TextStyle(fontSize: 13)))
                ],
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/gaming");
              }),
        ));
  });
}

void _internalSudokuGenerate(List<dynamic> args) {
  LEVEL level = args[0];
  SendPort sendPort = args[1];

  Sudoku sudoku = Sudoku.generator(level);
  List<int> puzzle = sudoku.puzzle;
  log.d("数独生成完毕");
  log.d(puzzle);
  sendPort.send(sudoku);
}

Future _sudokuGenerate(BuildContext context, LEVEL level) async {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
            child: Container(
                padding: EdgeInsets.all(10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  Container(
                      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text("正在为你加载数独,请稍后"))
                ])));
      });

  ReceivePort receivePort = ReceivePort();

  Isolate isolate = await Isolate.spawn(
      _internalSudokuGenerate, [level, receivePort.sendPort]);
  var data = await receivePort.first;
  Sudoku sudoku = data;
  SudokuState state = ScopedModel.of<SudokuState>(context);
  state.initialize(sudoku: sudoku, level: level);
  state.updateStatus(SudokuGameStatus.pause);
  receivePort.close();
  isolate.kill(priority: Isolate.immediate);
  log.d("receivePort.listen done!");

  // dismiss dialog
  Navigator.pop(context);
}

Widget _newGameButton(BuildContext context) {
  return _buttonWrapper(
      context,
      (_) => CupertinoButton(
          color: Colors.blue,
          child: Text(
            "新游戏",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Widget cancelView = SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width,
                child: Container(
                    margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: CupertinoButton(
//                      color: Colors.red,
                      child: Text("取消"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    )));

            List<Widget> buttons = [];
            LEVEL_NAMES.forEach((level, name) {
              var levelName = name;

              Widget button = SizedBox(
                  height: 60,
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                      margin: EdgeInsets.all(2.0),
                      child: CupertinoButton(
                        child: Text(
                          levelName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          log.d("begin generator Sudoku with level : $level");
                          await _sudokuGenerate(context, level);
                          Navigator.popAndPushNamed(context, "/gaming");

                          return Container(
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: Center(
                                  child: Text('Sudoku loading...',
                                      style: TextStyle(color: Colors.black),
                                      textDirection: TextDirection.ltr)));
                        },
                      )));

              buttons.add(button);
            });

            buttons.add(cancelView);

            showCupertinoModalBottomSheet(
              context: context,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                        child: Container(
                            height: 300,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: buttons))),
                  ),
                );
              },
            );
          }));
}

class _BootstrapPageState extends State<BootstrapPage> {
  @override
  Widget build(BuildContext context) {
    Widget body = Container(
        color: Colors.white,
        padding: EdgeInsets.all(20.0),
        child: Center(
            child: Column(
          children: <Widget>[
            // logo
            Expanded(
                flex: 1,
                child: Container(
                    alignment: Alignment.center,
                    color: Colors.white,
                    width: 400,
                    height: 400,
                    child: Image(
                      image: AssetImage("assets/image/logo.png"),
                    ))),
            Expanded(
                flex: 1,
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  // 继续游戏
                  _continueGameButton(context),
                  // 新游戏
                  _newGameButton(context),
                  // 扫一扫
                  _scanButton(context),
                ]))
          ],
        )));

    return ScopedModelDescendant<SudokuState>(
        builder: (context, child, model) => Scaffold(body: body));
  }
}
