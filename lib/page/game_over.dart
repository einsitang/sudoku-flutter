import 'package:flutter/material.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/util/localization_util.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

@immutable
class GameOverPage extends StatelessWidget {
  final bool _isWinner;
  final Level _level;
  final String _timer;

  GameOverPage({
    required String timer,
    required bool isWinner,
    required Level level,
  })  : _timer = timer,
        _isWinner = isWinner,
        _level = level,
        super(key: const Key('game_over_page'));

  @override
  Widget build(BuildContext context) {
    // define i18n begin
    final String elapsedTimeText =
        AppLocalizations.of(context)!.elapsedTimeText;
    final String winnerConclusionText =
        AppLocalizations.of(context)!.winnerConclusionText;
    final String failureConclusionText =
        AppLocalizations.of(context)!.failureConclusionText;
    final String levelLabel =
        LocalizationUtils.localizationLevelName(context, _level);
    // define i18n end

    String title, conclusion;
    Function playSoundEffect;
    if (_isWinner) {
      title = "Well Done!";
      conclusion = winnerConclusionText.replaceFirst("%level%", levelLabel);
      playSoundEffect = SoundEffect.solveVictory;
    } else {
      title = "Failure";
      conclusion = failureConclusionText.replaceFirst("%level%", levelLabel);
      playSoundEffect = SoundEffect.gameOver;
    }

    // sound effect : victory or failure
    playSoundEffect();

    Widget gameOverWidget = Scaffold(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
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
                              color:
                                  _isWinner ? Colors.black : Colors.redAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            )))),
                Expanded(
                    flex: 2,
                    child: Column(children: [
                      Container(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            25.0, 0.0, 25.0, 0.0),
                        child: Text(conclusion,
                            style: TextStyle(fontSize: 16, height: 1.5)),
                      ),
                      Container(
                          margin: EdgeInsets.fromLTRB(0, 15, 0, 10),
                          child: Text("$elapsedTimeText : $_timer's",
                              style: TextStyle(color: Colors.blue))),
                      Container(
                          padding: EdgeInsets.all(10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                    icon: Icon(Icons.thumb_up),
                                    onPressed: null),
                                IconButton(
                                    icon: Icon(Icons.exit_to_app),
                                    onPressed: () {
                                      Navigator.pop(context, "exit");
                                    })
                              ]))
                    ]))
              ],
            )));

    return gameOverWidget;
  }
}
