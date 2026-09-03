import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
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
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

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
    Locale('ms'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ms, this message translates to:
  /// **'WARIS'**
  String get appTitle;

  /// No description provided for @familyHome.
  ///
  /// In ms, this message translates to:
  /// **'Keluarga saya'**
  String get familyHome;

  /// No description provided for @tapToStart.
  ///
  /// In ms, this message translates to:
  /// **'Ketik untuk bermula'**
  String get tapToStart;

  /// No description provided for @yourName.
  ///
  /// In ms, this message translates to:
  /// **'Nama anda'**
  String get yourName;

  /// No description provided for @connectSomeone.
  ///
  /// In ms, this message translates to:
  /// **'Hubungkan seseorang'**
  String get connectSomeone;

  /// No description provided for @relSpouse.
  ///
  /// In ms, this message translates to:
  /// **'Pasangan'**
  String get relSpouse;

  /// No description provided for @relFather.
  ///
  /// In ms, this message translates to:
  /// **'Bapa'**
  String get relFather;

  /// No description provided for @relMother.
  ///
  /// In ms, this message translates to:
  /// **'Ibu'**
  String get relMother;

  /// No description provided for @relSon.
  ///
  /// In ms, this message translates to:
  /// **'Anak lelaki'**
  String get relSon;

  /// No description provided for @relDaughter.
  ///
  /// In ms, this message translates to:
  /// **'Anak perempuan'**
  String get relDaughter;

  /// No description provided for @relSibling.
  ///
  /// In ms, this message translates to:
  /// **'Adik-beradik'**
  String get relSibling;

  /// No description provided for @name.
  ///
  /// In ms, this message translates to:
  /// **'Nama'**
  String get name;

  /// No description provided for @male.
  ///
  /// In ms, this message translates to:
  /// **'Lelaki'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ms, this message translates to:
  /// **'Perempuan'**
  String get female;

  /// No description provided for @alive.
  ///
  /// In ms, this message translates to:
  /// **'Hidup'**
  String get alive;

  /// No description provided for @deceased.
  ///
  /// In ms, this message translates to:
  /// **'Meninggal'**
  String get deceased;

  /// No description provided for @add.
  ///
  /// In ms, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @connect.
  ///
  /// In ms, this message translates to:
  /// **'Hubungkan'**
  String get connect;

  /// No description provided for @focusOnPerson.
  ///
  /// In ms, this message translates to:
  /// **'Fokus pada orang ini'**
  String get focusOnPerson;

  /// No description provided for @skip.
  ///
  /// In ms, this message translates to:
  /// **'Langkau'**
  String get skip;

  /// No description provided for @deathSimulationPhase4.
  ///
  /// In ms, this message translates to:
  /// **'Simulasi kematian (Fasa 4)'**
  String get deathSimulationPhase4;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ms':
      return LMs();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
