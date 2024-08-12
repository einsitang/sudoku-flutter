import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/sudoku_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/page/bootstrap.dart';
import 'package:sudoku/page/sudoku_game.dart';
import 'package:sudoku/state/sudoku_state.dart';

import 'ml/detector.dart';

final Logger log = Logger();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // warmed up effect when application build before
  _soundEffectWarmedUp() async {
    await SoundEffect.init();
  }

  _modelWarmedUp() async {
    // warmed up sudoku-detector and digits-detector
    await DetectorFactory.getSudokuDetector();
    await DetectorFactory.getDigitsDetector();
  }

  Future<SudokuState> _loadState() async {
    await _soundEffectWarmedUp();
    await _modelWarmedUp();
    return await SudokuState.resumeFromDB();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SudokuState>(
      future: _loadState(),
      builder: (context, AsyncSnapshot<SudokuState> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Center(
                  child: Text('Sudoku Application initializing...',
                      style: TextStyle(color: Colors.black),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.hasError) {
          log.w("here is builder future throws error you should see it");
          log.w(snapshot.error);
        }
        SudokuState sudokuState = snapshot.data ?? SudokuState();
        BootstrapPage bootstrapPage = BootstrapPage(title: "Loading");
        SudokuGamePage sudokuGamePage = SudokuGamePage(title: "Sudoku");

        return ScopedModel<SudokuState>(
          model: sudokuState,
          child: MaterialApp(
            title: 'Sudoku',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
//             locale: Locale("en"), // i18n debug
            supportedLocales: AppLocalizations.supportedLocales,
            home: bootstrapPage,
            routes: <String, WidgetBuilder>{
              "/bootstrap": (context) => bootstrapPage,
              "/newGame": (context) => sudokuGamePage,
              "/gaming": (context) => sudokuGamePage
            },
          ),
        );
      },
    );
  }
}
