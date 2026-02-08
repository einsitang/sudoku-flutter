import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/page/bootstrap.dart';
import 'package:sudoku/page/sudoku_game.dart';
import 'package:sudoku/state/sudoku_state.dart';

import 'constant.dart';
import 'firebase_options.dart';
import 'ml/detector.dart';
import 'size_extension.dart';

final Logger log = Logger();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // firebase init
  _firebaseInit() async {
    if (!Constant.enableGoogleFirebase) {
      log.i("Google Firebase is disable.");
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Flutter Not Catch Error Handler
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    // Flutter Async Error Handler
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // Flutter Isolate Context Error Handler
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await FirebaseCrashlytics.instance.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
        fatal: true,
      );
    }).sendPort);
  }

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
    await _firebaseInit();
    await _soundEffectWarmedUp();
    await _modelWarmedUp();
    return await SudokuState.resumeFromDB();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context, 390, 844);
    return FutureBuilder<SudokuState>(
      future: _loadState(),
      builder: (context, AsyncSnapshot<SudokuState> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Center(
                child: Text('Sudoku Application initializing...',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    textDirection: TextDirection.ltr),
              ));
        }
        if (snapshot.hasError) {
          log.w("here is builder future throws error you should see it");
          final e = snapshot.error;
          final stackTrace = snapshot.stackTrace;
          log.w(e, stackTrace: stackTrace);
        }
        SudokuState sudokuState = snapshot.data ?? SudokuState();
        BootstrapPage bootstrapPage = BootstrapPage(title: "Loading");
        SudokuGamePage sudokuGamePage = SudokuGamePage(
          title: "Sudoku",
        );

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
            // locale: Locale("zh"), // i18n debug
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
