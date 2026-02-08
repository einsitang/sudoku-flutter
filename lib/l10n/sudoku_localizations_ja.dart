// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sudoku_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '数独クール';

  @override
  String get menuNewGame => '新規ゲーム';

  @override
  String get menuContinueGame => 'ゲームを続ける';

  @override
  String get menuAISolver => '数独スナップショット';

  @override
  String get levelCancel => 'キャンセル';

  @override
  String get levelEasy => '簡単';

  @override
  String get levelMedium => '中級';

  @override
  String get levelHard => '困難です';

  @override
  String get levelExpert => '専門家です';

  @override
  String get sudokuGenerateText => '数独を読み込んでいます。少々お待ちください...';

  @override
  String get gameStatusInitialize => '初期化';

  @override
  String get gameStatusGaming => '進行中';

  @override
  String get gameStatusPause => '一時停止';

  @override
  String get gameStatusFailure => '失敗';

  @override
  String get gameStatusVictory => '勝利';

  @override
  String get wrongInputAlertText => '入力が間違っています\nあと %attempts% 回試行できます';

  @override
  String get gotItText => '了解しました';

  @override
  String get levelText => '難易度';

  @override
  String get tipsText => 'ヒントです';

  @override
  String get enableMarkText => '草稿です';

  @override
  String get closeMarkText => '解答します';

  @override
  String get exitGameText => '退場します';

  @override
  String get exitGameContentText => 'このラウンドの数独を終了しますか？';

  @override
  String get openText => '開く';

  @override
  String get cancelText => 'キャンセル';

  @override
  String get pauseText => '一時停止です';

  @override
  String get markText => 'メモ';

  @override
  String get pauseGameText => 'ゲームが一時停止しています';

  @override
  String get elapsedTimeText => '経過時間';

  @override
  String get continueGameContentText => '画面をダブルタップしてゲームを再開します';

  @override
  String get winnerConclusionText => 'おめでとうございます！[%level%]の数独チャレンジをクリアしました！';

  @override
  String get failureConclusionText =>
      '残念ながら、[%level%]の数独でエラー回数が多すぎました。チャレンジに失敗しました！';

  @override
  String get aiSolverLensScanTipsText => 'カメラを使用して数独を撮影して認識します';
}
