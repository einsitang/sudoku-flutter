import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/constant.dart';

Logger log = Logger();

class CrashlyticsUtil {
  static void recordError(dynamic error, dynamic stackTrace) {
    if (!Constant.enableGoogleFirebase) {
      log.w("not enable google firebase crashlytics service");
      log.w(error, stackTrace: stackTrace);
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
