import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:sudoku/constant.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/page/sudoku_pause_cover.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku/util/localization_util.dart';
import 'package:sudoku_dart/sudoku_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'game_over.dart';

final Logger log = Logger();
final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black54,
  shadowColor: Colors.blue,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

final ButtonStyle primaryFlatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: Colors.lightBlue,
  shadowColor: Colors.blue,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

const ideaAssetImage = AssetImage("assets/image/icon_idea.png");
const lifeAssetImage = AssetImage("assets/image/icon_life.png");
const logoAssetImage = AssetImage("assets/image/sudoku_logo.png");
const eraserAssetImage = AssetImage("assets/image/icon_eraser.png");

const Image ideaPng = Image(
  image: ideaAssetImage,
  width: 25,
  height: 25,
);
const Image lifePng = Image(
  image: lifeAssetImage,
  width: 25,
  height: 25,
);

final timerPauseAssetSvg = SvgPicture.asset(
  "assets/svg/timer_pause.svg",
  width: 40,
  height: 40,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcIn),
);

final lightbulbAssetSvg = SvgPicture.asset(
  "assets/svg/lightbulb.svg",
  width: 40,
  height: 40,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcIn),
);

final lightbulbDisableAssetSvg = SvgPicture.asset(
  "assets/svg/lightbulb.svg",
  width: 40,
  height: 40,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.black12, BlendMode.srcIn),
);

final noteAltAssetSvg = SvgPicture.asset(
  "assets/svg/note_alt.svg",
  width: 40,
  height: 40,
  clipBehavior: Clip.antiAliasWithSaveLayer,
  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcIn),
);

final exitToAppAssetSvg = SvgPicture.asset(
  "assets/svg/exit_to_app.svg",
  width: 40,
  height: 40,
  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcIn),
);

class SudokuGamePage extends StatefulWidget {
  SudokuGamePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _SudokuGamePageState createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage>
    with WidgetsBindingObserver {
  // animation
  late final ValueAdapter _animationValue;
  late AnimationController _animationCtrl;
  var _animationDuration = 1.5.seconds;

  /// if _onTapFuncLock is true , tap event will not work
  var _onTapFuncLock = false;

  /// 选中的格子
  int _chooseSudokuBox = 0;

  // 与选中格子形成关联的格子集合 : 行 / 列 / 宫
  Set<int> _correlationChooseBoxes = {};

  /// 感知选中数字
  int _perceptionNum = 0;
  bool _markOpen = false;
  bool _manualPause = false;

  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  _aboutDialogAction(BuildContext context) {
    Widget appIcon = GestureDetector(
        child: Image(image: logoAssetImage, width: 45, height: 45),
        onDoubleTap: () {
          WidgetBuilder columnWidget = (BuildContext context) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(image: logoAssetImage),
                  CupertinoButton(
                    child: Text(
                      AppLocalizations.of(context)!.appName,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  )
                ]);
          };
          showDialog(context: context, builder: columnWidget);
        });
    return showAboutDialog(
        applicationIcon: appIcon,
        applicationName: AppLocalizations.of(context)!.appName,
        context: context,
        children: <Widget>[
          GestureDetector(
            child: Text(
              "Github Repository",
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () async {
              if (await canLaunchUrlString(Constant.githubRepository)) {
                if (Platform.isAndroid) {
                  await launchUrlString(
                    Constant.githubRepository,
                    mode: LaunchMode.externalApplication,
                    browserConfiguration: BrowserConfiguration(showTitle: true),
                    webOnlyWindowName: "Sudoku-Flutter Github Repository",
                  );
                } else {
                  await launchUrlString(Constant.githubRepository,
                      mode: LaunchMode.externalApplication);
                }
              } else {
                log.e(
                    "can't open browser to url : ${Constant.githubRepository}");
              }
            },
          ),
          Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
              padding: EdgeInsets.all(0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sudoku powered by Flutter",
                        style: TextStyle(fontSize: 12)),
                    Text(Constant.githubRepository,
                        style: TextStyle(fontSize: 12))
                  ]))
        ]);
  }

  bool _isOnlyReadGrid(int index) => (_state.sudoku?.puzzle[index] ?? 0) != -1;

  // 游戏盘点，检查是否游戏结束
  // check the game is done
  void _gameStackCount() {
    if (_state.isComplete) {
      _pauseTimer();
      _state.updateStatus(SudokuGameStatus.success);
      return _gameOver();
    }
  }

  /// game over trigger function
  /// 游戏结束触发 执行判断逻辑
  void _gameOver() async {
    bool isWinner = _state.status == SudokuGameStatus.success;

    setState(() {
      _onTapFuncLock = true;
      if (isWinner) {
        // play winner shining animate
        _animationValue.value = 1.0;
        _animationCtrl.forward(from: 0.0);
      }
    });

    var gameOverPage = GameOverPage(
      timer: _state.timer,
      level: _state.level!,
      isWinner: isWinner,
    );

    // route to game over show widget page
    PageRouteBuilder gameOverPageRouteBuilder = PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, animation, _) => ScaleTransition(
            scale: Tween(begin: 3.0, end: 1.0).animate(animation),
            child: gameOverPage));

    // if winner , delay and play winner shining animate
    Future.delayed(isWinner ? _animationDuration * 1.1 : 0.ms, () async {
      String signal =
          await Navigator.of(context).push(gameOverPageRouteBuilder);
      switch (signal) {
        case "exit":
        default:
          Navigator.pop(context);
          break;
      }
    });
  }

  // fill zone [ 1 - 9 ]
  Widget _fillZone(BuildContext context) {
    List<Widget> fillTools = List.generate(9, (index) {
      int num = index + 1;
      bool hasNumStock = _state.hasNumStock(num);
      var fillOnPressed;
      if (!hasNumStock) {
        fillOnPressed = null;
      } else {
        fillOnPressed = () async {
          log.d("input : $num");
          if (_onTapFuncLock) {
            return;
          }

          if (_isOnlyReadGrid(_chooseSudokuBox)) {
            // 非填空项
            return;
          }
          if (_state.status != SudokuGameStatus.gaming) {
            // 未在游戏进行时
            return;
          }
          if (_markOpen) {
            /// markOpen , mean use mark notes
            log.d("填写笔记");
            _state.switchMark(_chooseSudokuBox, num);
          } else {
            // 填写数字
            _state.switchRecord(_chooseSudokuBox, num);
            // 判断真伪
            if (_state.record[_chooseSudokuBox] != -1 &&
                _state.sudoku!.solution[_chooseSudokuBox] != num) {
              // 填入错误数字 wrong answer on _chooseSudokuBox with num
              _state.lifeLoss();

              if (_state.life <= 0) {
                // 游戏结束
                return _gameOver();
              }

              // "\nWrong Input\nYou can't afford ${_state.life} more turnovers"
              String wrongInputAlertText =
                  AppLocalizations.of(context)!.wrongInputAlertText;
              wrongInputAlertText = wrongInputAlertText.replaceFirst(
                  "%attempts%", "${_state.life}");
              String gotItText = AppLocalizations.of(context)!.gotItText;

              showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    // sound stuff error
                    SoundEffect.stuffError();
                    return CupertinoAlertDialog(
                      title: Text("Oops..."),
                      content: Text(wrongInputAlertText),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(gotItText),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  });

              return;
            }
            _gameStackCount();
          }
        };
      }

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
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                        color: _markOpen ? markFontColor : recordFontColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: fillOnPressed)));
    });

    fillTools.add(Expanded(
        flex: 1,
        child: Container(
            child: CupertinoButton(
                padding: EdgeInsets.all(8),
                child: Image(image: eraserAssetImage, width: 40, height: 40),
                onPressed: () {
                  log.d("""
                  when ${_chooseSudokuBox + 1} is not a puzzle , then clean the choose \n
                  清除 ${_chooseSudokuBox + 1} 选型 , 如果他不是固定值的话
                  """);
                  if (_isOnlyReadGrid(_chooseSudokuBox)) {
                    // read only item , skip it - 只读格
                    return;
                  }
                  if (_state.status != SudokuGameStatus.gaming) {
                    // not playing , skip it - 未在游戏进行时
                    return;
                  }
                  _state.cleanMark(_chooseSudokuBox);
                  _state.cleanRecord(_chooseSudokuBox);
                }))));

    return Container(
        height: 40,
        width: MediaQuery.of(context).size.width,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(children: fillTools),
        ));
  }

  Widget _toolZone(BuildContext context) {
    // pause button tap function
    var pauseOnPressed = () {
      if (_onTapFuncLock) {
        return;
      }
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

    // tips button tap function
    var tipsOnPressed;
    if (_state.hint > 0) {
      tipsOnPressed = () {
        if (_onTapFuncLock) {
          return;
        }
        // tips next cell answer
        log.d("top tips button");
        int hint = _state.hint;
        if (hint <= 0) {
          return;
        }
        List<int> puzzle = _state.sudoku!.puzzle;
        List<int> solution = _state.sudoku!.solution;
        List<int> record = _state.record;
        // random point tips
        int randomBeginPoint = new Random().nextInt(puzzle.length);
        for (int i = 0; i < puzzle.length; i++) {
          int index = (i + randomBeginPoint) % puzzle.length;
          if (puzzle[index] == -1 && record[index] == -1) {
            SoundEffect.answerTips();
            _state.setRecord(index, solution[index]);
            _state.hintLoss();
            _updateChooseState(index);
            _gameStackCount();

            // update choose state
            _updateChooseState(index);
            return;
          }
        }
      };
    }

    // mark button tap function
    var markOnPressed = () {
      if (_onTapFuncLock) {
        return;
      }
      log.d("enable mark function - 启用笔记功能");
      setState(() {
        _markOpen = !_markOpen;
      });
    };
    // define i18n text begin
    var exitGameText = AppLocalizations.of(context)!.exitGameText;
    var cancelText = AppLocalizations.of(context)!.cancelText;
    var pauseText = AppLocalizations.of(context)!.pauseText;
    var tipsText = AppLocalizations.of(context)!.tipsText;
    var enableMarkText = AppLocalizations.of(context)!.enableMarkText;
    var closeMarkText = AppLocalizations.of(context)!.closeMarkText;
    var exitGameContentText = AppLocalizations.of(context)!.exitGameContentText;
    // define i18n text end
    var exitGameOnPressed = () async {
      if (_onTapFuncLock) {
        return;
      }
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: Text(exitGameText,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text(exitGameContentText),
                actions: [
                  TextButton(
                    child: Text(exitGameText),
                    style: flatButtonStyle,
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    child: Text(cancelText),
                    style: primaryFlatButtonStyle,
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                ]);
          }).then((val) {
        bool confirm = val;
        if (confirm == true) {
          // exit the game 退出游戏
          ScopedModel.of<SudokuState>(context).initialize();
          Navigator.pop(context);
        }
      });
    };

    var _toolContentWrapper =
        (svgPicture, label, {Color labelColor = Colors.black54}) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          Container(
            // color: Colors.black,
            padding: EdgeInsets.all(5),
            child: SimpleShadow(child: svgPicture),
          ),
          Container(
            alignment: Alignment.center,
            width: 80,
            height: 25,
            child: Text(
              label,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    };

    return Container(
        // color: Colors.black,
        padding: EdgeInsets.all(5),
        child: Row(children: <Widget>[
          // 暂停游戏 pause game button
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: CupertinoButton(
                  padding: EdgeInsets.all(3),
                  onPressed: pauseOnPressed,
                  child: _toolContentWrapper(timerPauseAssetSvg, pauseText),
                ),
                // child: Text(pauseText, style: TextStyle(fontSize: 15)),
              )),
          // 提示 tips
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(3),
                    onPressed: tipsOnPressed,
                    child: _state.hint > 0
                        ? _toolContentWrapper(lightbulbAssetSvg, tipsText)
                        : _toolContentWrapper(
                            lightbulbDisableAssetSvg, tipsText,
                            labelColor: Colors.black12),
                    // child: Text(tipsText, style: TextStyle(fontSize: 15)),
                  ))),
          // 笔记 mark record
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(3),
                    onPressed: markOnPressed,
                    child: _toolContentWrapper(noteAltAssetSvg,
                        _markOpen ? closeMarkText : enableMarkText),
                    // child: Text("${_markOpen ? closeMarkText : enableMarkText}",
                    //     style: TextStyle(fontSize: 15)),
                  ))),
          // 退出 exit
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(3),
                    onPressed: exitGameOnPressed,
                    child: _toolContentWrapper(exitToAppAssetSvg, exitGameText),
                    // child: Text(exitGameText, style: TextStyle(fontSize: 15)),
                  ))),
          // 占位符，测试用
          // Expanded(flex: 5, child: Text("")),
        ]));
  }

  Widget _willPopWidget(BuildContext context, Widget child,
      PopInvokedWithResultCallback onWillPop) {
    return PopScope(
      child: child,
      canPop: true,
      onPopInvokedWithResult: onWillPop,
    );
    // return WillPopScope(child: child, onWillPop: onWillPop);
  }

  /// 计算网格背景色
  Color _gridCellBgColor(int index) {
    Color gridCellBackgroundColor;

    if (index == _chooseSudokuBox) {
      // 选中的格子
      gridCellBackgroundColor = Color.fromARGB(255, 0x7A, 0xF8, 0xF8);
    } else if (_correlationChooseBoxes.contains(index)) {
      // 关联的格子
      gridCellBackgroundColor = Color.fromARGB(255, 0x44, 0xCE, 0xF6);
    } else {
      // 其他格子
      if (Matrix.getZone(index: index).isOdd) {
        // 奇数宫 1,3,5,7 背景为白色 (从 0 开始)
        gridCellBackgroundColor = Colors.white;
      } else {
        // 偶数宫 0,2,4,6,8 背景为浅灰色
        // gridCellBackgroundColor = Color.fromARGB(255, 0xDF, 0xDF, 0xDF);
        gridCellBackgroundColor = Color.fromARGB(255, 0xEE, 0xEE, 0xEE);
      }
    }
    return gridCellBackgroundColor;
  }

  ///
  /// 正常网格控件
  ///
  Widget _gridCellWidget(
      BuildContext context, int index, int num, GestureTapCallback onTap) {
    Sudoku sudoku = _state.sudoku!;
    List<int> puzzle = sudoku.puzzle;
    List<int> solution = sudoku.solution;
    List<int> record = _state.record;
    int num = puzzle[index];

    double fontSize = 25;
    Color textColor = Colors.blueGrey.shade500;
    FontWeight textFontWeight = FontWeight.w700;
    String? fontFamily = null;
    if (puzzle[index] == -1) {
      num = record[index];
      // from puzzle number with readonly
      textFontWeight = FontWeight.normal;

      if (record[index] != -1 && record[index] != solution[index]) {
        // is wrong input because not match solution
        textColor = Colors.red;
      } else {
        // from user input num
        textColor = Colors.black87;
        fontFamily = "handwriting_digits";
        fontSize = 28;
      }
    }

    var _textContainer = Text('${num == -1 ? '' : num}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: textFontWeight,
          color: textColor,
        ));
    if (num != -1 && num == _perceptionNum) {
      _textContainer = Text('${num == -1 ? '' : num}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: textFontWeight,
            color: textColor,
            // 提示线
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: Colors.deepOrangeAccent,
            decorationThickness: 1.5,
          ));
    }

    final _cellContainer = Center(
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(1),
        decoration: BoxDecoration(
            color: _gridCellBgColor(index),
            border: Border.all(color: Colors.black12)),
        child: _textContainer,
      ),
    );

    return InkWell(
      highlightColor: Colors.blue,
      customBorder: Border.all(color: Colors.blue),
      child: _cellContainer,
      onTap: onTap,
    );
  }

  ///
  /// 笔记网格控件
  ///
  Widget _markGridCellWidget(
      BuildContext context, int index, GestureTapCallback onTap) {
    Widget markGrid = InkWell(
        highlightColor: Colors.blue,
        customBorder: Border.all(color: Colors.blue),
        onTap: onTap,
        child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
                color: _gridCellBgColor(index),
                border: Border.all(color: Colors.black12)),
            child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (BuildContext context, int _index) {
                  double fontSize = 13;
                  int markNum =
                      _state.mark[index][_index + 1] ? _index + 1 : -1;
                  String markNumText = '${markNum == -1 ? "" : markNum}';
                  var _textContainer = Text(markNumText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: fontSize,
                          fontStyle: FontStyle.italic,
                          color: _chooseSudokuBox == index
                              ? Colors.white
                              : Color.fromARGB(255, 0x26, 0x7A, 0xBC)));

                  // 感知提示
                  if (markNum != -1 && markNum == _perceptionNum) {
                    _textContainer = Text(markNumText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontStyle: FontStyle.italic,
                          color: _chooseSudokuBox == index
                              ? Colors.white
                              : Color.fromARGB(255, 0x26, 0x7A, 0xBC),
                          // 提示线
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.wavy,
                          decorationColor: Colors.deepOrangeAccent,
                          decorationThickness: 1.2,
                        ));
                  }

                  return _textContainer;
                })));

    return markGrid;
  }

  /// 更新关联
  /// 用户每次选择框(cell)时,需要更新其关联的 行 列 宫 方便背景色和效果变更
  _updateCorrelationChooseBox() {
    // same zones
    List<int> zoneIndexes =
        Matrix.getZoneIndexes(zone: Matrix.getZone(index: _chooseSudokuBox));
    // same rows
    List<int> rowIndexes =
        Matrix.getRowIndexes(Matrix.getRow(_chooseSudokuBox));
    // same columns
    List<int> colIndexes =
        Matrix.getColIndexes(Matrix.getCol(_chooseSudokuBox));

    // 关联的格子
    Set<int> indexSet = Set();
    indexSet.addAll(zoneIndexes);
    indexSet.addAll(rowIndexes);
    indexSet.addAll(colIndexes);
    _correlationChooseBoxes = indexSet;
  }

  /// 选择感知
  /// 用户触摸每一个框(cell),尝试获得其触摸的数字,然后赋予提醒效果
  _choosePerception(int index) {
    Sudoku sudoku = _state.sudoku!;
    List<int> puzzle = sudoku.puzzle;
    List<int> record = _state.record;

    int perceptionNum = -1;
    if (record[index] > 0) {
      perceptionNum = record[index];
    } else if (puzzle[index] > 0) {
      perceptionNum = puzzle[index];
    }

    _perceptionNum = perceptionNum;
  }

  _updateChooseState(index) {
    setState(() {
      _chooseSudokuBox = index;
      _updateCorrelationChooseBox();
      _choosePerception(index);
    });
  }

  // cell onTop function
  _cellOnTapBuilder(index) {
    return () {
      if (_onTapFuncLock) {
        return;
      }
      _updateChooseState(index);
    };
  }

  Widget _bodyWidget(BuildContext context) {
    if (_state.sudoku == null) {
      return Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Center(
              child: Text('Sudoku Exiting...',
                  style: TextStyle(color: Colors.black),
                  textDirection: TextDirection.ltr)));
    }
    var textValueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

    /// status zone
    /// life / tips / timer on here
    var _indicator = Container(
      height: 50,
      padding: EdgeInsets.all(10.0),
      child: Row(children: <Widget>[
        Expanded(
            flex: 1,
            child: Row(children: <Widget>[
              lifePng,
              Text(" x ${_state.life}", style: textValueStyle)
            ])),
        // indicator
        Expanded(
          flex: 2,
          child: Container(
              alignment: AlignmentDirectional.center,
              child: Text(
                "${LocalizationUtils.localizationLevelName(context, _state.level!)} - ${_state.timer} - ${LocalizationUtils.localizationGameStatus(context, _state.status)}",
                style: TextStyle(fontSize: 15),
              )),
        ),
        // tips
        Expanded(
            flex: 1,
            child: Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                  ideaPng,
                  Text(" x ${_state.hint}", style: textValueStyle)
                ])))
      ]),
    );

    /// 9 x 9 cells sudoku puzzle board
    /// the whole sudoku game draw it here
    var _sudokuPuzzleBoard = GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 81,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
            itemBuilder: ((BuildContext context, int index) {
              int num = -1;
              if (_state.sudoku?.puzzle.length == 81) {
                num = _state.sudoku!.puzzle[index];
              }

              // 用户做标记
              bool isUserMark = _state.sudoku!.puzzle[index] == -1 &&
                  _state.mark[index].any((element) => element);

              return isUserMark
                  ? _markGridCellWidget(
                      context, index, _cellOnTapBuilder(index))
                  : _gridCellWidget(
                      context, index, num, _cellOnTapBuilder(index));
            }))
        .animate(
      autoPlay: false,
      adapter: _animationValue,
      onInit: (ctrl) {
        _animationCtrl = ctrl;
      },
    )
        .shimmer(
      duration: _animationDuration,
      angle: 0.55,
      size: 0.1,
      colors: [
        Colors.white10,
        Colors.white,
        Colors.white10,
      ],
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _indicator,
          _sudokuPuzzleBoard,

          /// user input zone
          /// use fillZone choose number fill cells or mark notes
          /// use toolZone to pause / exit game
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
    WidgetsBinding.instance.removeObserver(this);
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
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationValue = ValueAdapter(0);
    _updateChooseState(0);
    _gaming();
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
  Timer? _timer;

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
    log.d("timer begin");
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
      if (_timer!.isActive) {
        _timer!.cancel();
      }
    }
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
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
        context,
        ScopedModelDescendant<SudokuState>(
            builder: (context, child, model) => _bodyWidget(context)),
        (bool didPop, result) async {
          if (didPop) {
            _pause();
          }
        },
      ),
    );

    return scaffold;
  }
}
