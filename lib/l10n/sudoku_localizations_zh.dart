// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sudoku_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '数独酷';

  @override
  String get menuNewGame => '新游戏';

  @override
  String get menuContinueGame => '继续游戏';

  @override
  String get menuAISolver => '数独快拍';

  @override
  String get levelCancel => '取消';

  @override
  String get levelEasy => '简单';

  @override
  String get levelMedium => '中等';

  @override
  String get levelHard => '困难';

  @override
  String get levelExpert => '专家';

  @override
  String get sudokuGenerateText => '正在为你加载数独,请稍后...';

  @override
  String get gameStatusInitialize => '初始化';

  @override
  String get gameStatusGaming => '进行中';

  @override
  String get gameStatusPause => '暂停';

  @override
  String get gameStatusFailure => '失败';

  @override
  String get gameStatusVictory => '胜利';

  @override
  String get wrongInputAlertText => '填写错误\n你还可以尝试 %attempts% 次';

  @override
  String get gotItText => '明白';

  @override
  String get levelText => '难度';

  @override
  String get tipsText => '随机提示';

  @override
  String get enableMarkText => '启用笔记';

  @override
  String get closeMarkText => '关闭笔记';

  @override
  String get exitGameText => '退出游戏';

  @override
  String get exitGameContentText => '是否要结束本轮数独？';

  @override
  String get openText => '打开';

  @override
  String get cancelText => '取消';

  @override
  String get pauseText => '暂停游戏';

  @override
  String get markText => '笔记';

  @override
  String get pauseGameText => '游戏暂停';

  @override
  String get elapsedTimeText => '耗时';

  @override
  String get continueGameContentText => '双击屏幕继续游戏';

  @override
  String get winnerConclusionText => '恭喜你完成 [%level%] 数独挑战!';

  @override
  String get failureConclusionText => '很遗憾,本轮 [%level%] 数独错误次数太多，挑战失败!';

  @override
  String get aiSolverLensScanTipsText => '请对准数独拍照进行识别';
}
