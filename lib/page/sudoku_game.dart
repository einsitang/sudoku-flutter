import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/page/sudoku_pause_cover.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

final Logger log = Logger();

class SudokuGamePage extends StatefulWidget {
  SudokuGamePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _SudokuGamePageState createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage> with WidgetsBindingObserver {
  int _chooseSudokuBox = 0;
  bool _markOpen = false;
  bool _manualPause = false;

  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  void _aboutDialogAction(BuildContext context) {
    Widget appIcon = GestureDetector(
        child: Image(image: AssetImage("assets/image/about_me.jpg"), width: 30, height: 30),
        onDoubleTap: () {
          return showDialog(
              context: context,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Image(image: AssetImage("assets/image/about_me.jpg")),
                CupertinoButton(
                  child: Text("死月半子"),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                )
              ]));
        });
    return showAboutDialog(applicationIcon: appIcon, context: context, children: <Widget>[
      Text("咦? 你来看我啦!!"),
      Container(
          margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
          padding: EdgeInsets.all(0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Sudoku powered by Flutter", style: TextStyle(fontSize: 12)),
            Text("OpenSource coming soon", style: TextStyle(fontSize: 12))
          ]))
    ]);
  }

  Image _ideaPng = Image(
    image: AssetImage("assets/image/icon_idea.png"),
    width: 25,
    height: 25,
  );
  Image _lifePng = Image(
    image: AssetImage("assets/image/icon_life.png"),
    width: 25,
    height: 25,
  );

  bool _isOnlyReadGrid(int index) => _state.sudoku.puzzle[index] != -1;

  // 触发游戏结束
  void _gameOver() {
    bool isWinner = _state.status == SudokuGameStatus.success;
    String title, conclusion;
    if (isWinner) {
      title = "God Job!";
      conclusion = "恭喜你完成 [${LEVEL_NAMES[_state.level]}] 数独挑战";
    } else {
      title = "Failure";
      conclusion = "很遗憾,本轮 [${LEVEL_NAMES[_state.level]}] 数独错误次数太多，挑战失败!";
    }

    Navigator.of(context)
        .push(PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, _, __) {
              return Scaffold(
                  backgroundColor: Colors.white.withOpacity(0.80),
                  body: Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                              flex: 1,
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Text(title,
                                      style: TextStyle(
                                          color: isWinner ? Colors.black : Colors.redAccent,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)))),
                          Expanded(
                              flex: 2,
                              child: Column(children: [
                                Text(conclusion, style: TextStyle(fontSize: 15)),
                                Container(
                                    margin: EdgeInsets.fromLTRB(0, 15, 0, 10),
                                    child: Text("用时  ${_state.timer}'s", style: TextStyle(color: Colors.blue))),
                                Container(
                                    padding: EdgeInsets.all(10),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Offstage(
                                          offstage: _state.status == SudokuGameStatus.success,
                                          child: IconButton(
                                              icon: Icon(Icons.tv),
                                              onPressed: () {
                                                Navigator.pop(context, "ad");
                                              })),
                                      IconButton(
                                          icon: Icon(Icons.thumb_up),
                                          onPressed: () {
                                            Navigator.pop(context, "share");
                                          }),
                                      IconButton(
                                          icon: Icon(Icons.exit_to_app),
                                          onPressed: () {
                                            Navigator.pop(context, "exit");
                                          })
                                    ]))
                              ]))
                        ],
                      )));
            }))
        .then((value) {
      String signal = value;
      switch (signal) {
        case "ad":
          // @TODO give a extra life
          break;
        case "exit":
        default:
          Navigator.pop(context);
          break;
      }
    });
  }

  Widget _fillZone(BuildContext context) {
    List<Widget> fillTools = List.generate(9, (index) {
      int num = index + 1;
      bool hasNumStock = _state.hasNumStock(num);
      var fillOnPressed = !hasNumStock
          ? null
          : () {
              log.d("正在输入 $num");
              if (_isOnlyReadGrid(_chooseSudokuBox)) {
                // 非填空项
                return;
              }
              if (_state.status != SudokuGameStatus.gaming) {
                // 未在游戏进行时
                return;
              }
              if (_markOpen) {
                // 填写笔记
                log.d("填写笔记");
                _state.switchMark(_chooseSudokuBox, num);
              } else {
                // 填写数字
                _state.switchRecord(_chooseSudokuBox, num);
                // 判断真伪
                if (_state.record[_chooseSudokuBox] != -1 && _state.sudoku.answer[_chooseSudokuBox] != num) {
                  // 填入错误数字
                  _state.lifeLoss();
                  if (_state.life <= 0) {
                    // 游戏结束
                    return _gameOver();
                  }
                  showDialog(context: context, builder: (_) => AlertDialog(content: Text("输入错误")));

                  return;
                }
                // 判断进度
                if (_state.isComplete) {
                  _pauseTimer();
                  _state.updateStatus(SudokuGameStatus.success);
                  return _gameOver();
                }
              }
            };

      Color recordFontColor = hasNumStock ? Colors.black : Colors.white;
      Color recordBgColor = hasNumStock ? Colors.black12 : Colors.white24;

      Color markFontColor = hasNumStock ? Colors.white : Colors.white;
      Color markBgColor = hasNumStock ? Colors.black : Colors.white24;

      return Expanded(
          flex: 1,
          child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(border: BorderDirectional()),
              child: CupertinoButton(
                  color: _markOpen ? markBgColor : recordBgColor,
                  padding: EdgeInsets.all(1),
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: _markOpen ? markFontColor : recordFontColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  onPressed: fillOnPressed)));
    });

    fillTools.add(Expanded(
        flex: 1,
        child: Container(
            child: CupertinoButton(
                padding: EdgeInsets.all(8),
                child: Image(image: AssetImage("assets/image/icon_eraser.png"), width: 40, height: 40),
                onPressed: () {
                  log.d('清除 ${_chooseSudokuBox + 1} 选型 , 如果他不是固定值的话');
                  if (_isOnlyReadGrid(_chooseSudokuBox)) {
                    // 只读格
                    return;
                  }
                  if (_state.status != SudokuGameStatus.gaming) {
                    // 未在游戏进行时
                    return;
                  }
                  _state.cleanMark(_chooseSudokuBox);
                  _state.cleanRecord(_chooseSudokuBox);
                }))));

    return Align(
        alignment: Alignment.centerLeft,
        child: Container(height: 40, width: MediaQuery.of(context).size.width, child: Row(children: fillTools)));
  }

  Widget _toolZone(BuildContext context) {
    var pauseOnPressed = () {
      if (_state.status != SudokuGameStatus.gaming) {
        return;
      }

      // 标记手动暂停
      setState(() {
        _manualPause = true;
      });

      _pause();
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (BuildContext context, _, __) {
                return SudokuPauseCoverPage();
              })).then((_) {
        _gaming();

        // 解除手动暂停
        setState(() {
          _manualPause = false;
        });
      });
    };
    var tipsOnPressed;
    var markOnPressed = () {
      log.d("启用笔记功能");
      setState(() {
        _markOpen = !_markOpen;
      });
    };
    var exitGameOnPressed = () async {
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(title: Text("退出游戏"), content: Text("是否要结束本轮数独？"), actions: [
              FlatButton(
                  child: Text("退出游戏"),
                  onPressed: () {
                    // dismiss with confirm true
                    Navigator.pop(context, true);
                  }),
              FlatButton(
                color: Colors.blue,
                child: Text("取消"),
                onPressed: () {
                  // dismiss with cancel
                  Navigator.pop(context, false);
                },
              )
            ]);
          }).then((val) {
        bool confirm = val;
        if (confirm == true) {
          // 退出游戏
          log.d("exit the game !!");
          ScopedModel.of<SudokuState>(context).initialize();
          Navigator.pop(context);
        }
      });
    };
    return Container(
        height: 50,
        padding: EdgeInsets.all(5),
        child: Row(children: <Widget>[
          // 暂停游戏
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: pauseOnPressed,
                      child: Text("暂停", style: TextStyle(fontSize: 15))))),
          // 提示
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: tipsOnPressed,
                      child: Text("提示", style: TextStyle(fontSize: 15))))),
          // 笔记
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: markOnPressed,
                      child: Text("${_markOpen ? '关闭' : '启用'}笔记", style: TextStyle(fontSize: 15))))),
          // 退出
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: exitGameOnPressed,
                      child: Text("退出游戏", style: TextStyle(fontSize: 15)))))
        ]));
  }

  Widget _willPopWidget(BuildContext context, Widget child, Function onWillPop) {
    return new WillPopScope(child: child, onWillPop: onWillPop);
  }

  /// 计算网格背景色
  Color _gridInWellBgColor(int index) {
    Color gridWellBackgroundColor;
    // 同宫
    List<int> zoneIndexes = Matrix.getZoneIndexes(zone: Matrix.getZone(index: index));
    // 同行
    List<int> rowIndexes = Matrix.getRowIndexes(Matrix.getRow(index));
    // 同列
    List<int> colIndexes = Matrix.getColIndexes(Matrix.getCol(index));

    Set indexSet = Set();
    indexSet.addAll(zoneIndexes);
    indexSet.addAll(rowIndexes);
    indexSet.addAll(colIndexes);

    if (index == _chooseSudokuBox) {
      gridWellBackgroundColor = Color.fromARGB(255, 0x70, 0xF3, 0xFF);
    } else if (indexSet.contains(_chooseSudokuBox)) {
      gridWellBackgroundColor = Color.fromARGB(255, 0x44, 0xCE, 0xF6);
    } else {
      if (Matrix.getZone(index: index).isOdd) {
        gridWellBackgroundColor = Colors.white;
      } else {
        gridWellBackgroundColor = Color.fromARGB(255, 0xCC, 0xCC, 0xCC);
      }
    }
    return gridWellBackgroundColor;
  }

  ///
  /// 正常网格控件
  ///
  Widget _gridInWellWidget(BuildContext context, int index, int num, Function onTap) {
    Sudoku sudoku = _state.sudoku;
    List<int> puzzle = sudoku.puzzle;
    List<int> answer = sudoku.answer;
    List<int> record = _state.record;
    bool readOnly = true;
    bool isWrong = false;
    int num = puzzle[index];
    if (puzzle[index] == -1) {
      num = record[index];
      readOnly = false;

      if (record[index] != -1 && record[index] != answer[index]) {
        isWrong = true;
      }
    }
    return InkWell(
        highlightColor: Colors.blue,
        customBorder: Border.all(color: Colors.blue),
        child: Center(
          child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(color: _gridInWellBgColor(index), border: Border.all(color: Colors.black12)),
            child: Text(
              '${num == -1 ? '' : num}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: readOnly ? FontWeight.w800 : FontWeight.normal,
                  color: readOnly ? Colors.blueGrey : (isWrong ? Colors.red : Color.fromARGB(255, 0x3B, 0x2E, 0x7E))),
            ),
          ),
        ),
        onTap: onTap);
  }

  ///
  /// 笔记网格控件
  ///
  Widget _markGridWidget(BuildContext context, int index, Function onTap) {
    Widget markGrid = InkWell(
        highlightColor: Colors.blue,
        customBorder: Border.all(color: Colors.blue),
        onTap: onTap,
        child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(color: _gridInWellBgColor(index), border: Border.all(color: Colors.black12)),
            child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemBuilder: (BuildContext context, int _index) {
                  String markNum = '${_state.mark[index][_index + 1] ? _index + 1 : ""}';
                  return Text(markNum,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _chooseSudokuBox == index ? Colors.white : Color.fromARGB(255, 0x16, 0x85, 0xA9),
                          fontSize: 12));
                })));

    return markGrid;
  }

  Widget _bodyWidget(BuildContext context) {
    if (_state.sudoku == null) {
      return Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Center(
              child:
                  Text('Sudoku Exiting...', style: TextStyle(color: Colors.black), textDirection: TextDirection.ltr)));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 50,
            padding: EdgeInsets.all(10.0),
//                color: Colors.red,
            child: Row(children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Row(children: <Widget>[_lifePng, Text(" x ${_state.life}", style: TextStyle(fontSize: 18))])),
              // indicator
              Expanded(
                flex: 2,
                child: Container(
                    alignment: AlignmentDirectional.center,
                    child: Text("${LEVEL_NAMES[_state.level]} - ${_state.timer} - ${STATUS_NAMES[_state.status]}")),
              ),
              // tips
              Expanded(
                  flex: 1,
                  child: Container(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[_ideaPng, Text(" x ${_state.hint}", style: TextStyle(fontSize: 18))])))
            ]),
          ),
          GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 81,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
              itemBuilder: ((BuildContext context, int index) {
                int num = -1;
                if (_state.sudoku?.puzzle?.length == 81) {
                  num = _state.sudoku.puzzle[index];
                }

                wellOnTap() {
                  setState(() {
                    _chooseSudokuBox = index;
                  });

                  if (num != -1) {
                    return;
                  }

                  log.d('正在输入 : $index');
                }

                // 用户做标记
                bool isUserMark =
                    _state.sudoku.puzzle[index] == -1 && _state.mark[index] != null && _state.mark[index].isNotEmpty;

                if (isUserMark) {
                  return _markGridWidget(context, index, wellOnTap);
                }

                return _gridInWellWidget(context, index, num, wellOnTap);
              })),
          // 此处输入框
          Container(margin: EdgeInsets.fromLTRB(0, 5, 0, 5)),
          _fillZone(context),
          _toolZone(context)
        ],
      ),
    );
  }

  @override
  void deactivate() {
    log.d("on deactivate");
    super.deactivate();
  }

  @override
  void dispose() {
    log.d("on dispose");
    _pauseTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    log.d("on init state and _puzzle : ${_state.sudoku.puzzle}");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gaming();
  }

  @override
  void didChangeDependencies() {
    log.d("didChangeDependencies");
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(SudokuGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    log.d("on did update widget");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        log.d("is paused app lifecycle state");
        _pause();
        break;
      case AppLifecycleState.resumed:
        log.d("is resumed app lifecycle state");
        if (!_manualPause) {
          _gaming();
        }
        break;
      default:
        break;
    }
  }

  // 定时器
  Timer _timer;

  void _gaming() {
    if (_state.status == SudokuGameStatus.pause) {
      log.d("on _gaming");
      _state.updateStatus(SudokuGameStatus.gaming);
      _state.persistent();
      _beginTimer();
    }
  }

  void _pause() {
    if (_state.status == SudokuGameStatus.gaming) {
      log.d("on _pause");
      _state.updateStatus(SudokuGameStatus.pause);
      _state.persistent();
      _pauseTimer();
    }
  }

  // 开始计时
  void _beginTimer() {
    log.d("开始计时");
    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_state.status == SudokuGameStatus.gaming) {
          _state.tick();
          return;
        }
        timer.cancel();
      });
    }
  }

  // 暂停计时
  void _pauseTimer() {
    if (_timer != null) {
      if (_timer.isActive) {
        _timer.cancel();
      }
    }
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    log.d("on build");
    Scaffold scaffold = Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () {
            return _aboutDialogAction(context);
          },
        )
      ]),
      body: _willPopWidget(
          context, ScopedModelDescendant<SudokuState>(builder: (context, child, model) => _bodyWidget(context)),
          () async {
        _pause();
        return true;
      }),
    );

    return scaffold;
  }
}
