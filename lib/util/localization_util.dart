import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/sudoku_localizations.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

/// LocalizationUtils
class LocalizationUtils {
  static String localizationLevelName(BuildContext context, Level level) {
    switch (level) {
      case Level.easy:
        return AppLocalizations.of(context)!.levelEasy;
      case Level.medium:
        return AppLocalizations.of(context)!.levelMedium;
      case Level.hard:
        return AppLocalizations.of(context)!.levelHard;
      case Level.expert:
        return AppLocalizations.of(context)!.levelExpert;
    }
  }

  static String localizationGameStatus(
      BuildContext context, SudokuGameStatus status) {
    switch (status) {
      case SudokuGameStatus.initialize:
        return AppLocalizations.of(context)!.gameStatusInitialize;
      case SudokuGameStatus.gaming:
        return AppLocalizations.of(context)!.gameStatusGaming;
      case SudokuGameStatus.pause:
        return AppLocalizations.of(context)!.gameStatusPause;
      case SudokuGameStatus.fail:
        return AppLocalizations.of(context)!.gameStatusFailure;
      case SudokuGameStatus.success:
        return AppLocalizations.of(context)!.gameStatusVictory;
    }
  }

}
