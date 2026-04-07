import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ko'),
  ];

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @add.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @select.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get select;

  /// No description provided for @bookmark.
  ///
  /// In ko, this message translates to:
  /// **'북마크'**
  String get bookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In ko, this message translates to:
  /// **'북마크 해제'**
  String get removeBookmark;

  /// No description provided for @memo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memo;

  /// No description provided for @editMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 편집'**
  String get editMemo;

  /// No description provided for @addMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 추가'**
  String get addMemo;

  /// No description provided for @memoHint.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 메모를 입력하세요'**
  String get memoHint;

  /// No description provided for @label.
  ///
  /// In ko, this message translates to:
  /// **'라벨'**
  String get label;

  /// No description provided for @editLabelAction.
  ///
  /// In ko, this message translates to:
  /// **'라벨 편집'**
  String get editLabelAction;

  /// No description provided for @labelManagement.
  ///
  /// In ko, this message translates to:
  /// **'라벨 관리'**
  String get labelManagement;

  /// No description provided for @labelManagementSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'라벨 추가, 수정, 삭제 및 알림 설정'**
  String get labelManagementSubtitle;

  /// No description provided for @addNewLabel.
  ///
  /// In ko, this message translates to:
  /// **'신규 라벨 추가'**
  String get addNewLabel;

  /// No description provided for @newLabel.
  ///
  /// In ko, this message translates to:
  /// **'새 라벨'**
  String get newLabel;

  /// No description provided for @addNewLabelTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 라벨 추가'**
  String get addNewLabelTitle;

  /// No description provided for @addLabelTitle.
  ///
  /// In ko, this message translates to:
  /// **'라벨 추가'**
  String get addLabelTitle;

  /// No description provided for @editLabelTitle.
  ///
  /// In ko, this message translates to:
  /// **'라벨 수정'**
  String get editLabelTitle;

  /// No description provided for @labelName.
  ///
  /// In ko, this message translates to:
  /// **'라벨 이름'**
  String get labelName;

  /// No description provided for @labelNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: Flutter, 디자인'**
  String get labelNameHint;

  /// No description provided for @color.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get color;

  /// No description provided for @createLabelPrompt.
  ///
  /// In ko, this message translates to:
  /// **'라벨을 만들어 아티클을 분류해보세요'**
  String get createLabelPrompt;

  /// No description provided for @addLabelsFirst.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 라벨을 먼저 추가해주세요'**
  String get addLabelsFirst;

  /// No description provided for @deleteLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨 삭제'**
  String get deleteLabel;

  /// No description provided for @deleteLabelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'\'{name}\'\' 라벨을 삭제할까요?\n{count}개 아티클에서 이 라벨이 제거됩니다.'**
  String deleteLabelConfirm(String name, int count);

  /// No description provided for @allArticles.
  ///
  /// In ko, this message translates to:
  /// **'전체 아티클'**
  String get allArticles;

  /// No description provided for @articleCountText.
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 아티클'**
  String articleCountText(int count);

  /// No description provided for @labelArticleCountText.
  ///
  /// In ko, this message translates to:
  /// **'{labels} · {count}개의 아티클'**
  String labelArticleCountText(String labels, int count);

  /// No description provided for @noArticles.
  ///
  /// In ko, this message translates to:
  /// **'아티클이 없습니다.'**
  String get noArticles;

  /// No description provided for @noReadArticles.
  ///
  /// In ko, this message translates to:
  /// **'읽은 아티클이 없습니다.'**
  String get noReadArticles;

  /// No description provided for @noUnreadArticles.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 아티클이 없습니다.'**
  String get noUnreadArticles;

  /// No description provided for @deleteArticle.
  ///
  /// In ko, this message translates to:
  /// **'아티클 삭제'**
  String get deleteArticle;

  /// No description provided for @deleteArticleConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 아티클을 삭제할까요?'**
  String get deleteArticleConfirm;

  /// No description provided for @deleteSelectedConfirm.
  ///
  /// In ko, this message translates to:
  /// **'선택한 {count}개 아티클을 삭제할까요?'**
  String deleteSelectedConfirm(int count);

  /// No description provided for @selectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String selectedCount(int count);

  /// No description provided for @read.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get read;

  /// No description provided for @unread.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음'**
  String get unread;

  /// No description provided for @markAsRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음으로 변경'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음으로 변경'**
  String get markAsUnread;

  /// No description provided for @tabAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 ({count})'**
  String tabAll(int count);

  /// No description provided for @tabUnread.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음 ({count})'**
  String tabUnread(int count);

  /// No description provided for @tabRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음 ({count})'**
  String tabRead(int count);

  /// No description provided for @totalAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 {count}'**
  String totalAll(int count);

  /// No description provided for @totalUnread.
  ///
  /// In ko, this message translates to:
  /// **'안읽음 {count}'**
  String totalUnread(int count);

  /// No description provided for @library.
  ///
  /// In ko, this message translates to:
  /// **'보관함'**
  String get library;

  /// No description provided for @labelStatus.
  ///
  /// In ko, this message translates to:
  /// **'라벨별 현황'**
  String get labelStatus;

  /// No description provided for @overallReadingStatus.
  ///
  /// In ko, this message translates to:
  /// **'전체 읽기 현황'**
  String get overallReadingStatus;

  /// No description provided for @articlesRead.
  ///
  /// In ko, this message translates to:
  /// **'{read} / {total} 아티클 읽음'**
  String articlesRead(int read, int total);

  /// No description provided for @labelCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 라벨'**
  String labelCount(int count);

  /// No description provided for @all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// No description provided for @bookmarks.
  ///
  /// In ko, this message translates to:
  /// **'북마크'**
  String get bookmarks;

  /// No description provided for @noBookmarks.
  ///
  /// In ko, this message translates to:
  /// **'북마크한 아티클이 없습니다.'**
  String get noBookmarks;

  /// No description provided for @noReadBookmarks.
  ///
  /// In ko, this message translates to:
  /// **'읽은 북마크가 없습니다.'**
  String get noReadBookmarks;

  /// No description provided for @noUnreadBookmarks.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 북마크가 없습니다.'**
  String get noUnreadBookmarks;

  /// No description provided for @noArticlesToSwipe.
  ///
  /// In ko, this message translates to:
  /// **'스와이프할 아티클이 없습니다'**
  String get noArticlesToSwipe;

  /// No description provided for @addLinksHint.
  ///
  /// In ko, this message translates to:
  /// **'공유 시트에서 링크를 추가해보세요!'**
  String get addLinksHint;

  /// No description provided for @noUnreadInLabel.
  ///
  /// In ko, this message translates to:
  /// **'선택한 라벨에 읽지 않은 아티클이 없어요'**
  String get noUnreadInLabel;

  /// No description provided for @openInBrowser.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 열기'**
  String get openInBrowser;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get theme;

  /// No description provided for @howToUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 방법'**
  String get howToUse;

  /// No description provided for @howToUseSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Clib 사용법을 다시 확인해요'**
  String get howToUseSubtitle;

  /// No description provided for @systemSettings.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get systemSettings;

  /// No description provided for @systemSettingsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'기기 설정에 따라 자동 전환'**
  String get systemSettingsSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ko, this message translates to:
  /// **'라이트 모드'**
  String get lightMode;

  /// No description provided for @onboardingSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'링크를 저장하세요'**
  String get onboardingSaveTitle;

  /// No description provided for @onboardingSaveSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 버튼 하나로\n어디서든 아티클을 수집할 수 있어요'**
  String get onboardingSaveSubtitle;

  /// No description provided for @onboardingSaveHint.
  ///
  /// In ko, this message translates to:
  /// **'브라우저, SNS, 유튜브에서 공유하기 → Clib'**
  String get onboardingSaveHint;

  /// No description provided for @onboardingSwipeTitle.
  ///
  /// In ko, this message translates to:
  /// **'스와이프로 읽으세요'**
  String get onboardingSwipeTitle;

  /// No description provided for @onboardingSwipeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'카드를 넘기며 읽을 콘텐츠를 결정하세요'**
  String get onboardingSwipeSubtitle;

  /// No description provided for @onboardingSwipeHint.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 → 읽음 처리  ·  왼쪽 → 나중에'**
  String get onboardingSwipeHint;

  /// No description provided for @onboardingLibraryTitle.
  ///
  /// In ko, this message translates to:
  /// **'나만의 라이브러리'**
  String get onboardingLibraryTitle;

  /// No description provided for @onboardingLibrarySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'라벨로 정리하고, 알림으로 다시 찾아오세요'**
  String get onboardingLibrarySubtitle;

  /// No description provided for @onboardingLibraryHint.
  ///
  /// In ko, this message translates to:
  /// **'저장만 하던 습관에서 읽는 습관으로'**
  String get onboardingLibraryHint;

  /// No description provided for @skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @start.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get start;

  /// No description provided for @labelNotification.
  ///
  /// In ko, this message translates to:
  /// **'{name} 알림'**
  String labelNotification(String name);

  /// No description provided for @receiveNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림 받기'**
  String get receiveNotification;

  /// No description provided for @daysOfWeek.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get daysOfWeek;

  /// No description provided for @selectTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get selectTime;

  /// No description provided for @time.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get time;

  /// No description provided for @notificationChannelName.
  ///
  /// In ko, this message translates to:
  /// **'Clib 라벨 알림'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'라벨별 미읽음 아티클 알림'**
  String get notificationChannelDesc;

  /// No description provided for @unreadNotification.
  ///
  /// In ko, this message translates to:
  /// **'읽지 않은 아티클 {count}개가 있어요!'**
  String unreadNotification(int count);

  /// No description provided for @allReadNotification.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽었어요! 🎉'**
  String get allReadNotification;

  /// No description provided for @dayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get daySun;

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String daysAgo(int count);

  /// No description provided for @saveToClib.
  ///
  /// In ko, this message translates to:
  /// **'Clib에 저장'**
  String get saveToClib;

  /// No description provided for @editArticle.
  ///
  /// In ko, this message translates to:
  /// **'아티클 편집'**
  String get editArticle;

  /// No description provided for @platform.
  ///
  /// In ko, this message translates to:
  /// **'플랫폼'**
  String get platform;

  /// No description provided for @articleStats.
  ///
  /// In ko, this message translates to:
  /// **'{total}개 아티클 · {read}개 읽음'**
  String articleStats(int total, int read);

  /// No description provided for @account.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get account;

  /// No description provided for @loginSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 다른 기기에서도 사용할 수 있어요'**
  String get loginSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 로그인'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 로그인'**
  String get signInWithApple;

  /// No description provided for @signOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 하시겠어요?'**
  String get signOutConfirm;

  /// No description provided for @signOutDescription.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃해도 이 기기의 데이터는 유지됩니다.'**
  String get signOutDescription;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ko, this message translates to:
  /// **'계정을 삭제하시겠어요?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In ko, this message translates to:
  /// **'클라우드 데이터가 모두 삭제됩니다. 이 기기의 데이터는 유지됩니다.'**
  String get deleteAccountDescription;

  /// No description provided for @syncComplete.
  ///
  /// In ko, this message translates to:
  /// **'동기화 완료'**
  String get syncComplete;

  /// No description provided for @syncing.
  ///
  /// In ko, this message translates to:
  /// **'동기화 중...'**
  String get syncing;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다'**
  String get loginFailed;

  /// No description provided for @notificationDeviceOnly.
  ///
  /// In ko, this message translates to:
  /// **'알림은 이 기기에서만 울립니다. 다른 기기에서는 별도로 설정해 주세요.'**
  String get notificationDeviceOnly;

  /// No description provided for @addArticle.
  ///
  /// In ko, this message translates to:
  /// **'아티클 추가'**
  String get addArticle;

  /// No description provided for @urlHint.
  ///
  /// In ko, this message translates to:
  /// **'URL을 입력하세요'**
  String get urlHint;

  /// No description provided for @invalidUrl.
  ///
  /// In ko, this message translates to:
  /// **'유효하지 않은 URL입니다'**
  String get invalidUrl;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In ko, this message translates to:
  /// **'붙여넣기'**
  String get pasteFromClipboard;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
