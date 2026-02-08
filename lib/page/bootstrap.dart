import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:logger/logger.dart' hide Level;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/native/sudoku.dart';
import 'package:sudoku/size_extension.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku/util/localization_util.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import 'ai_scan.dart';

final Logger log = Logger();

class BootstrapPage extends StatefulWidget {
  BootstrapPage({Key? key, required this.title}) : super(key: key);

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

Widget _aiSolverButton(BuildContext context) {
  String label = AppLocalizations.of(context)!.menuAISolver;
  return Offstage(
      offstage: false,
      child: _buttonWrapper(
          context,
          (content) => CupertinoButton(
                color: Colors.blue,
                child: Text(
                  "$label / test /",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "montserrat",
                  ),
                ),
                onPressed: () async {
                  log.d("AI Solver Scanner");

                  WidgetsFlutterBinding.ensureInitialized();

                  final cameras = await availableCameras();
                  final firstCamera = cameras.first;
                  final aiScanPage =
                      AIScanPage(title: label, camera: firstCamera);

                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (BuildContext context, _, __) {
                            return aiScanPage;
                          }));
                },
              )));
}

Widget _continueGameButton(BuildContext context) {
  return ScopedModelDescendant<SudokuState>(builder: (context, child, state) {
    String buttonLabel = AppLocalizations.of(context)!.menuContinueGame;
    String continueMessage =
        "${LocalizationUtils.localizationLevelName(context, state.level ?? Level.easy)} - ${state.timer}";
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
                      child: Text(buttonLabel,
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold))),
                  Container(
                      child:
                          Text(continueMessage, style: TextStyle(fontSize: 13)))
                ],
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/gaming");
              }),
        ));
  });
}

Widget _newGameButton(BuildContext context) {
  return _buttonWrapper(
      context,
      (_) => CupertinoButton(
          color: Colors.blue,
          child: Text(
            AppLocalizations.of(context)!.menuNewGame,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            // cancel  button
            Widget cancelButton = SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width,
                child: Container(
                    child: CupertinoButton(
                  child: Text(
                    AppLocalizations.of(context)!.levelCancel,
                    style: TextStyle(color: Colors.black45),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                )));

            // iterative difficulty build buttons
            List<Widget> buttons = [];
            Level.values.forEach((Level level) {
              String levelName =
                  LocalizationUtils.localizationLevelName(context, level);
              buttons.add(SizedBox(
                  height: 60,
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                      margin: EdgeInsets.all(1.0),
                      child: CupertinoButton(
                        child: Text(
                          levelName,
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          log.d(
                              "begin generator Sudoku with level : $levelName");
                          await _sudokuGenerate(context, level);
                          Navigator.popAndPushNamed(context, "/gaming");
                        },
                      ))));
            });
            buttons.add(cancelButton);

            showCupertinoModalBottomSheet(
              context: context,
              barrierColor: Colors.black38,
              topRadius: Radius.circular(20),
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Material(
                        child: Container(
                            height: 320,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: buttons))),
                  ),
                );
              },
            );
          }));
}

void _internalSudokuGenerate(List<dynamic> args) {
  Level level = args[0];
  SendPort sendPort = args[1];

  DateTime beginTime, endTime;
  beginTime = DateTime.now();
  // 生成题目速度比较慢,尝试使用native生成 , 解题普遍速度较快,继续使用 sudoku_dart
  // native 生成 加上 dart 解题 速度提升非常显著
  List<int> puzzle = SudokuNativeHelper.instance.generate(level.index);
  Sudoku sudoku = Sudoku(puzzle);
  // Sudoku sudoku = Sudoku.generate(level);
  endTime = DateTime.now();
  var consumingTie =
      endTime.millisecondsSinceEpoch - beginTime.millisecondsSinceEpoch;
  log.d("数独生成完毕 耗时: $consumingTie'ms");
  sendPort.send(sudoku);
}

Future _sudokuGenerate(BuildContext context, Level level) async {
  String sudokuGenerateText = AppLocalizations.of(context)!.sudokuGenerateText;

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
          child: Container(
              padding: EdgeInsets.all(10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text("/ $sudokuGenerateText /",
                        style: TextStyle(fontSize: 13)))
              ]))));

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

class _BootstrapPageState extends State<BootstrapPage> {
  @override
  Widget build(BuildContext context) {
    Widget logo = Text(
      "/ suˈdoʊku: /",
      style: TextStyle(
        fontFamily: "montserrat",
        color: Colors.black,
        fontSize: (55.0).r,
      ),
    );

    Widget buttons = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () async {
            var languageCode = Localizations.localeOf(context).languageCode;
            await SoundEffect.sudokuSpeak(languageCode);
          },
          icon: Icon(
            size: 18,
            Icons.keyboard_voice_rounded,
            color: Colors.black26,
          ),
        )
            .animate()
            .fadeIn(delay: 1500.ms)
            .then()
            .animate(onPlay: (ctrl) => ctrl.loop(reverse: true))
            .scaleXY(end: 1.35, duration: 600.ms, delay: 2200.ms)
            .blurXY(end: 1.2, duration: 600.ms, delay: 2200.ms)
      ],
    );

    Widget banner = Container(
      alignment: Alignment.center,
      width: 400,
      // color:Colors.yellow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logo,
          buttons,
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 1500.ms)
        .moveY(
            delay: 800.ms, duration: 500.ms, begin: SizeConfig.screenHeight / 4)
        .then()
        .scaleXY(duration: 500.ms, begin: 1.25)
        .then()
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: false))
        .shimmer(
      angle: 0.65,
      delay: 800.ms,
      duration: 3500.ms,
      colors: [
        Colors.black,
        Colors.black45,
        Colors.white,
        Colors.black87,
        Colors.black,
      ],
    );

    Widget body = Container(
      color: Colors.white,
      padding: EdgeInsets.all(35.0),
      child: Center(
        child: Column(
          children: <Widget>[
            // logo
            Expanded(flex: 1, child: banner),
            Expanded(
              flex: 1,
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                // continue the game
                _continueGameButton(context),
                // new game
                _newGameButton(context),
                // ai solver scanner
                _aiSolverButton(context),
              ]).animate().fadeIn(
                      delay: 1200.ms,
                      duration: 1000.ms,
                      curve: Curves.bounceOut),
            )
          ],
        ),
      ),
    );

    return ScopedModelDescendant<SudokuState>(
        builder: (context, child, model) => Scaffold(body: body));
  }
}
