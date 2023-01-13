import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/state/sudoku_state.dart';

class SudokuPauseCoverPage extends StatefulWidget {
  SudokuPauseCoverPage({Key? key}) : super(key: key);

  @override
  _SudokuPauseCoverPageState createState() => _SudokuPauseCoverPageState();
}

class _SudokuPauseCoverPageState extends State<SudokuPauseCoverPage> {
  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  @override
  Widget build(BuildContext context) {
    TextStyle pageTextStyle = TextStyle(color: Colors.white);

    Widget titleView =
        Align(child: Text("游戏暂停", style: TextStyle(fontSize: 26)));
    Widget bodyView = Align(
        child: Column(children: [
      Expanded(flex: 3, child: titleView),
      Expanded(
          flex: 5,
          child: Column(children: [
            Text("难度 [${LevelNames[_state.level]}] 已用时 ${_state.timer}")
          ])),
      Expanded(
        flex: 1,
        child: Align(alignment: Alignment.center, child: Text("双击屏幕继续游戏")),
      )
    ]));

    var onDoubleTap = () {
      log.d("double click : leave this stack");
      Navigator.pop(context);
    };
    var onTap = () {
      log.d("single click , do nothing");
    };
    return GestureDetector(
        child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.98),
            body: DefaultTextStyle(child: bodyView, style: pageTextStyle)),
        onTap: onTap,
        onDoubleTap: onDoubleTap);
  }
}
