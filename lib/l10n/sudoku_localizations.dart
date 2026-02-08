import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'sudoku_localizations_en.dart';
import 'sudoku_localizations_fr.dart';
import 'sudoku_localizations_ja.dart';
import 'sudoku_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/sudoku_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sudoku'**
  String get appName;

  /// menu of 'new game' button text
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get menuNewGame;

  /// menu of 'continue game' button text
  ///
  /// In en, this message translates to:
  /// **'Continue Game'**
  String get menuContinueGame;

  /// No description provided for @menuAISolver.
  ///
  /// In en, this message translates to:
  /// **'Sudoku Lens'**
  String get menuAISolver;

  /// No description provided for @levelCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get levelCancel;

  /// No description provided for @levelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get levelEasy;

  /// No description provided for @levelMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get levelMedium;

  /// No description provided for @levelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get levelHard;

  /// No description provided for @levelExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get levelExpert;

  /// No description provided for @sudokuGenerateText.
  ///
  /// In en, this message translates to:
  /// **'Generating your Sudoku...'**
  String get sudokuGenerateText;

  /// No description provided for @gameStatusInitialize.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get gameStatusInitialize;

  /// No description provided for @gameStatusGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get gameStatusGaming;

  /// No description provided for @gameStatusPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gameStatusPause;

  /// No description provided for @gameStatusFailure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get gameStatusFailure;

  /// No description provided for @gameStatusVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get gameStatusVictory;

  /// No description provided for @wrongInputAlertText.
  ///
  /// In en, this message translates to:
  /// **'Wrong Input\nYou can\'t afford %attempts% more turnovers'**
  String get wrongInputAlertText;

  /// No description provided for @gotItText.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotItText;

  /// No description provided for @levelText.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelText;

  /// No description provided for @tipsText.
  ///
  /// In en, this message translates to:
  /// **'Use Tips'**
  String get tipsText;

  /// No description provided for @enableMarkText.
  ///
  /// In en, this message translates to:
  /// **'Enable Note'**
  String get enableMarkText;

  /// No description provided for @closeMarkText.
  ///
  /// In en, this message translates to:
  /// **'Close Note'**
  String get closeMarkText;

  /// No description provided for @exitGameText.
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGameText;

  /// No description provided for @exitGameContentText.
  ///
  /// In en, this message translates to:
  /// **'Would you like to end this Sudoku round ?'**
  String get exitGameContentText;

  /// No description provided for @openText.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openText;

  /// No description provided for @cancelText.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelText;

  /// No description provided for @pauseText.
  ///
  /// In en, this message translates to:
  /// **'Pause Game'**
  String get pauseText;

  /// No description provided for @markText.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get markText;

  /// No description provided for @pauseGameText.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pauseGameText;

  /// No description provided for @elapsedTimeText.
  ///
  /// In en, this message translates to:
  /// **'elapsed time'**
  String get elapsedTimeText;

  /// No description provided for @continueGameContentText.
  ///
  /// In en, this message translates to:
  /// **'Double click the screen to continue playing'**
  String get continueGameContentText;

  /// No description provided for @winnerConclusionText.
  ///
  /// In en, this message translates to:
  /// **'Congratulations on completing the [%level%] Sudoku challenge!'**
  String get winnerConclusionText;

  /// No description provided for @failureConclusionText.
  ///
  /// In en, this message translates to:
  /// **'This round of Sudoku [%level%] had too many errors. Challenge failed!'**
  String get failureConclusionText;

  /// No description provided for @aiSolverLensScanTipsText.
  ///
  /// In en, this message translates to:
  /// **'take pictures to solve puzzle'**
  String get aiSolverLensScanTipsText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
