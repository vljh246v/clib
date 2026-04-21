// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get save => 'Speichern';

  @override
  String get saveFailed => 'Speichern fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirm => 'OK';

  @override
  String get add => 'Hinzufügen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get select => 'Auswählen';

  @override
  String get bookmark => 'Lesezeichen';

  @override
  String get removeBookmark => 'Lesezeichen entfernen';

  @override
  String get memo => 'Notiz';

  @override
  String get editMemo => 'Notiz bearbeiten';

  @override
  String get addMemo => 'Notiz hinzufügen';

  @override
  String get memoHint => 'Kurze Notiz schreiben';

  @override
  String get label => 'Label';

  @override
  String get editLabelAction => 'Labels bearbeiten';

  @override
  String get labelManagement => 'Labels verwalten';

  @override
  String get labelManagementSubtitle =>
      'Labels hinzufügen, bearbeiten, löschen und Erinnerungen einstellen';

  @override
  String get addNewLabel => 'Neues Label';

  @override
  String get newLabel => 'Neues Label';

  @override
  String get addNewLabelTitle => 'Neues Label';

  @override
  String get addLabelTitle => 'Label hinzufügen';

  @override
  String get editLabelTitle => 'Label bearbeiten';

  @override
  String get labelName => 'Labelname';

  @override
  String get labelNameHint => 'z. B. Flutter, Design';

  @override
  String get color => 'Farbe';

  @override
  String get createLabelPrompt => 'Erstelle Labels, um deine Artikel zu ordnen';

  @override
  String get addLabelsFirst => 'Füge zuerst Labels in den Einstellungen hinzu';

  @override
  String get deleteLabel => 'Label löschen';

  @override
  String deleteLabelConfirm(String name, int count) {
    return 'Label \'\'$name\'\' löschen?\nEs wird aus $count Artikeln entfernt.';
  }

  @override
  String get allArticles => 'Alle Artikel';

  @override
  String articleCountText(int count) {
    return '$count Artikel';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count Artikel';
  }

  @override
  String get noArticles => 'Noch keine Artikel vorhanden.';

  @override
  String get noReadArticles => 'Keine gelesenen Artikel.';

  @override
  String get noUnreadArticles => 'Keine ungelesenen Artikel.';

  @override
  String get deleteArticle => 'Artikel löschen';

  @override
  String get deleteArticleConfirm => 'Diesen Artikel löschen?';

  @override
  String deleteSelectedConfirm(int count) {
    return '$count ausgewählte Artikel löschen?';
  }

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get read => 'Gelesen';

  @override
  String get unread => 'Ungelesen';

  @override
  String get markAsRead => 'Als gelesen markieren';

  @override
  String get markAsUnread => 'Als ungelesen markieren';

  @override
  String tabAll(int count) {
    return 'Alle ($count)';
  }

  @override
  String tabUnread(int count) {
    return 'Ungelesen ($count)';
  }

  @override
  String tabRead(int count) {
    return 'Gelesen ($count)';
  }

  @override
  String totalAll(int count) {
    return 'Gesamt $count';
  }

  @override
  String totalUnread(int count) {
    return 'Ungelesen $count';
  }

  @override
  String get library => 'Bibliothek';

  @override
  String get labelStatus => 'Labels';

  @override
  String get overallReadingStatus => 'Lesefortschritt';

  @override
  String articlesRead(int read, int total) {
    return '$read von $total Artikeln gelesen';
  }

  @override
  String labelCount(int count) {
    return '$count Labels';
  }

  @override
  String get all => 'Alle';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get noBookmarks => 'Keine Artikel mit Lesezeichen.';

  @override
  String get noReadBookmarks => 'Keine gelesenen Lesezeichen.';

  @override
  String get noUnreadBookmarks => 'Keine ungelesenen Lesezeichen.';

  @override
  String get noArticlesToSwipe => 'Keine Artikel zum Durchblättern';

  @override
  String get addLinksHint =>
      'Teile Links aus anderen Apps, um sie hinzuzufügen!';

  @override
  String get noUnreadInLabel =>
      'Keine ungelesenen Artikel in den gewählten Labels';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get theme => 'Design';

  @override
  String get howToUse => 'So funktioniert\'s';

  @override
  String get howToUseSubtitle => 'Erfahre, wie du Clib nutzt';

  @override
  String get systemSettings => 'Systemstandard';

  @override
  String get systemSettingsSubtitle =>
      'Folgt automatisch den Geräteeinstellungen';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get lightMode => 'Hellmodus';

  @override
  String get onboardingSaveTitle => 'Speichere deine Links';

  @override
  String get onboardingSaveSubtitle =>
      'Sammle Artikel von überall\nmit nur einem Fingertipp';

  @override
  String get onboardingSaveHint =>
      'Aus Browser, Social Media, YouTube teilen → Clib';

  @override
  String get onboardingSwipeTitle => 'Wischen zum Lesen';

  @override
  String get onboardingSwipeSubtitle =>
      'Blättere durch Karten und entscheide, was du lesen willst';

  @override
  String get onboardingSwipeHint => 'Rechts → Gelesen  ·  Links → Später lesen';

  @override
  String get onboardingLibraryTitle => 'Deine persönliche Bibliothek';

  @override
  String get onboardingLibrarySubtitle =>
      'Ordne mit Labels, lass dich per Erinnerung zurückbringen';

  @override
  String get onboardingLibraryHint =>
      'Vom bloßen Speichern zum tatsächlichen Lesen';

  @override
  String get skip => 'Überspringen';

  @override
  String get next => 'Weiter';

  @override
  String get start => 'Los geht\'s';

  @override
  String labelNotification(String name) {
    return 'Erinnerungen für $name';
  }

  @override
  String get receiveNotification => 'Erinnerungen aktivieren';

  @override
  String get daysOfWeek => 'Wochentage';

  @override
  String get selectTime => 'Uhrzeit wählen';

  @override
  String get time => 'Uhrzeit';

  @override
  String get notificationChannelName => 'Clib-Erinnerungen';

  @override
  String get notificationChannelDesc =>
      'Erinnerungen an ungelesene Artikel nach Label';

  @override
  String unreadNotification(int count) {
    return 'Du hast noch $count ungelesene Artikel!';
  }

  @override
  String get allReadNotification => 'Alles gelesen! 🎉';

  @override
  String get dayMon => 'Mo';

  @override
  String get dayTue => 'Di';

  @override
  String get dayWed => 'Mi';

  @override
  String get dayThu => 'Do';

  @override
  String get dayFri => 'Fr';

  @override
  String get daySat => 'Sa';

  @override
  String get daySun => 'So';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String daysAgo(int count) {
    return 'Vor $count Tagen';
  }

  @override
  String get saveToClib => 'In Clib speichern';

  @override
  String get editArticle => 'Artikel bearbeiten';

  @override
  String get platform => 'Plattform';

  @override
  String articleStats(int total, int read) {
    return '$total Artikel · $read gelesen';
  }

  @override
  String get account => 'Konto';

  @override
  String get loginSubtitle =>
      'Melde dich an, um geräteübergreifend zu synchronisieren';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirm => 'Möchtest du dich abmelden?';

  @override
  String get signOutDescription =>
      'Deine Daten auf diesem Gerät bleiben erhalten.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountConfirm => 'Konto wirklich löschen?';

  @override
  String get deleteAccountDescription =>
      'Alle Cloud-Daten werden gelöscht. Die Daten auf diesem Gerät bleiben erhalten.';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get notificationDeviceOnly =>
      'Erinnerungen klingeln nur auf diesem Gerät. Richte sie auf anderen Geräten separat ein.';

  @override
  String get addArticle => 'Artikel hinzufügen';

  @override
  String get urlHint => 'Link eingeben';

  @override
  String get invalidUrl => 'Ungültiger Link';

  @override
  String get pasteFromClipboard => 'Einfügen';

  @override
  String get swipeRead => 'GELESEN';

  @override
  String get swipeLater => 'SPÄTER';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get privacyPolicySubtitle => 'Datenerhebung und -verwaltung';

  @override
  String get loginPolicyAgreement =>
      'Mit der Anmeldung stimmst du der Datenschutzrichtlinie zu.';

  @override
  String get guideSwipeTitle => 'Wischen zum Lesen';

  @override
  String get guideSwipeDesc =>
      'Nach rechts wischen für gelesen, nach links für später';

  @override
  String get guideAddTitle => 'Links manuell hinzufügen';

  @override
  String get guideAddDesc =>
      'Gib eine URL ein, um einen Artikel direkt hinzuzufügen';

  @override
  String get guideLibraryTitle => 'Deine Bibliothek verwalten';

  @override
  String get guideLibraryDesc =>
      'Artikel nach Labels sortiert durchstöbern und verwalten';

  @override
  String get guideSettingsTitle => 'Einstellungen anpassen';

  @override
  String get guideSettingsDesc =>
      'Labels verwalten, Design wechseln und Lese-Erinnerungen einrichten';

  @override
  String get guideTapToContinue => 'Tippen zum Fortfahren';
}
