// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sudoku_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Sudoku';

  @override
  String get menuNewGame => 'Nouveau jeu';

  @override
  String get menuContinueGame => 'Continuer le jeu';

  @override
  String get menuAISolver => 'Sudoku Lens';

  @override
  String get levelCancel => 'Annuler';

  @override
  String get levelEasy => 'Simple';

  @override
  String get levelMedium => 'Moyen';

  @override
  String get levelHard => 'Ardu';

  @override
  String get levelExpert => 'Expert';

  @override
  String get sudokuGenerateText =>
      'Chargement du sudoku pour vous, veuillez patienter...';

  @override
  String get gameStatusInitialize => 'Init';

  @override
  String get gameStatusGaming => 'En cours';

  @override
  String get gameStatusPause => 'Pause';

  @override
  String get gameStatusFailure => 'échouer';

  @override
  String get gameStatusVictory => 'la victoire';

  @override
  String get wrongInputAlertText =>
      'Wrong Input\nYou can\'t afford %attempts% more turnovers';

  @override
  String get gotItText => 'Got It';

  @override
  String get levelText => 'Difficulté';

  @override
  String get tipsText => 'Suggérer';

  @override
  String get enableMarkText => 'Enable Note';

  @override
  String get closeMarkText => 'Close Note';

  @override
  String get exitGameText => 'Quitter';

  @override
  String get exitGameContentText =>
      'Voulez-vous terminer cette partie de Sudoku ?';

  @override
  String get openText => 'Ouvrir';

  @override
  String get cancelText => 'Annuler';

  @override
  String get pauseText => 'Pause';

  @override
  String get markText => 'Note';

  @override
  String get pauseGameText => 'mettre le jeu en paused';

  @override
  String get elapsedTimeText => 'durée';

  @override
  String get continueGameContentText =>
      'Double-cliquez sur l’écran pour continuer à jouer';

  @override
  String get winnerConclusionText =>
      'Congratulations on completing the [%level%] Sudoku challenge!';

  @override
  String get failureConclusionText =>
      'Cette ronde de Sudoku [%level%] avait trop d’erreurs. Le défi a échoué!';

  @override
  String get aiSolverLensScanTipsText => 'take pictures to solve puzzle';
}
