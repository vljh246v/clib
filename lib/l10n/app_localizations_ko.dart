// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get confirm => '확인';

  @override
  String get add => '추가';

  @override
  String get edit => '수정';

  @override
  String get select => '선택';

  @override
  String get bookmark => '북마크';

  @override
  String get removeBookmark => '북마크 해제';

  @override
  String get memo => '메모';

  @override
  String get editMemo => '메모 편집';

  @override
  String get addMemo => '메모 추가';

  @override
  String get memoHint => '한 줄 메모를 입력하세요';

  @override
  String get label => '라벨';

  @override
  String get editLabelAction => '라벨 편집';

  @override
  String get labelManagement => '라벨 관리';

  @override
  String get labelManagementSubtitle => '라벨 추가, 수정, 삭제 및 알림 설정';

  @override
  String get addNewLabel => '신규 라벨 추가';

  @override
  String get newLabel => '새 라벨';

  @override
  String get addNewLabelTitle => '새 라벨 추가';

  @override
  String get addLabelTitle => '라벨 추가';

  @override
  String get editLabelTitle => '라벨 수정';

  @override
  String get labelName => '라벨 이름';

  @override
  String get labelNameHint => '예: Flutter, 디자인';

  @override
  String get color => '색상';

  @override
  String get createLabelPrompt => '라벨을 만들어 아티클을 분류해보세요';

  @override
  String get addLabelsFirst => '설정에서 라벨을 먼저 추가해주세요';

  @override
  String get deleteLabel => '라벨 삭제';

  @override
  String deleteLabelConfirm(String name, int count) {
    return '\'\'$name\'\' 라벨을 삭제할까요?\n$count개 아티클에서 이 라벨이 제거됩니다.';
  }

  @override
  String get allArticles => '전체 아티클';

  @override
  String articleCountText(int count) {
    return '$count개의 아티클';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count개의 아티클';
  }

  @override
  String get noArticles => '아티클이 없습니다.';

  @override
  String get noReadArticles => '읽은 아티클이 없습니다.';

  @override
  String get noUnreadArticles => '안 읽은 아티클이 없습니다.';

  @override
  String get deleteArticle => '아티클 삭제';

  @override
  String get deleteArticleConfirm => '이 아티클을 삭제할까요?';

  @override
  String deleteSelectedConfirm(int count) {
    return '선택한 $count개 아티클을 삭제할까요?';
  }

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get read => '읽음';

  @override
  String get unread => '안 읽음';

  @override
  String get markAsRead => '읽음으로 변경';

  @override
  String get markAsUnread => '안 읽음으로 변경';

  @override
  String tabAll(int count) {
    return '전체 ($count)';
  }

  @override
  String tabUnread(int count) {
    return '안 읽음 ($count)';
  }

  @override
  String tabRead(int count) {
    return '읽음 ($count)';
  }

  @override
  String totalAll(int count) {
    return '전체 $count';
  }

  @override
  String totalUnread(int count) {
    return '안읽음 $count';
  }

  @override
  String get library => '보관함';

  @override
  String get labelStatus => '라벨별 현황';

  @override
  String get overallReadingStatus => '전체 읽기 현황';

  @override
  String articlesRead(int read, int total) {
    return '$read / $total 아티클 읽음';
  }

  @override
  String labelCount(int count) {
    return '$count개 라벨';
  }

  @override
  String get all => '전체';

  @override
  String get bookmarks => '북마크';

  @override
  String get noBookmarks => '북마크한 아티클이 없습니다.';

  @override
  String get noReadBookmarks => '읽은 북마크가 없습니다.';

  @override
  String get noUnreadBookmarks => '안 읽은 북마크가 없습니다.';

  @override
  String get noArticlesToSwipe => '스와이프할 아티클이 없습니다';

  @override
  String get addLinksHint => '공유 시트에서 링크를 추가해보세요!';

  @override
  String get noUnreadInLabel => '선택한 라벨에 읽지 않은 아티클이 없어요';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String get settings => '설정';

  @override
  String get theme => '테마';

  @override
  String get howToUse => '사용 방법';

  @override
  String get howToUseSubtitle => 'Clib 사용법을 다시 확인해요';

  @override
  String get systemSettings => '시스템 설정';

  @override
  String get systemSettingsSubtitle => '기기 설정에 따라 자동 전환';

  @override
  String get darkMode => '다크 모드';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get onboardingSaveTitle => '링크를 저장하세요';

  @override
  String get onboardingSaveSubtitle => '공유 버튼 하나로\n어디서든 아티클을 수집할 수 있어요';

  @override
  String get onboardingSaveHint => '브라우저, SNS, 유튜브에서 공유하기 → Clib';

  @override
  String get onboardingSwipeTitle => '스와이프로 읽으세요';

  @override
  String get onboardingSwipeSubtitle => '카드를 넘기며 읽을 콘텐츠를 결정하세요';

  @override
  String get onboardingSwipeHint => '오른쪽 → 읽음 처리  ·  왼쪽 → 나중에';

  @override
  String get onboardingLibraryTitle => '나만의 라이브러리';

  @override
  String get onboardingLibrarySubtitle => '라벨로 정리하고, 알림으로 다시 찾아오세요';

  @override
  String get onboardingLibraryHint => '저장만 하던 습관에서 읽는 습관으로';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get start => '시작하기';

  @override
  String labelNotification(String name) {
    return '$name 알림';
  }

  @override
  String get receiveNotification => '알림 받기';

  @override
  String get daysOfWeek => '요일';

  @override
  String get selectTime => '시간 선택';

  @override
  String get time => '시간';

  @override
  String get notificationChannelName => 'Clib 라벨 알림';

  @override
  String get notificationChannelDesc => '라벨별 미읽음 아티클 알림';

  @override
  String unreadNotification(int count) {
    return '읽지 않은 아티클 $count개가 있어요!';
  }

  @override
  String get allReadNotification => '모두 읽었어요! 🎉';

  @override
  String get dayMon => '월';

  @override
  String get dayTue => '화';

  @override
  String get dayWed => '수';

  @override
  String get dayThu => '목';

  @override
  String get dayFri => '금';

  @override
  String get daySat => '토';

  @override
  String get daySun => '일';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get saveToClib => 'Clib에 저장';

  @override
  String get editArticle => '아티클 편집';

  @override
  String get platform => '플랫폼';

  @override
  String articleStats(int total, int read) {
    return '$total개 아티클 · $read개 읽음';
  }

  @override
  String get account => '계정';

  @override
  String get loginSubtitle => '로그인하면 다른 기기에서도 사용할 수 있어요';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get signInWithApple => 'Apple로 로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get signOutConfirm => '로그아웃 하시겠어요?';

  @override
  String get signOutDescription => '로그아웃해도 이 기기의 데이터는 유지됩니다.';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountConfirm => '계정을 삭제하시겠어요?';

  @override
  String get deleteAccountDescription =>
      '클라우드 데이터가 모두 삭제됩니다. 이 기기의 데이터는 유지됩니다.';

  @override
  String get syncComplete => '동기화 완료';

  @override
  String get syncing => '동기화 중...';

  @override
  String get loginFailed => '로그인에 실패했습니다';

  @override
  String get notificationDeviceOnly =>
      '알림은 이 기기에서만 울립니다. 다른 기기에서는 별도로 설정해 주세요.';

  @override
  String get addArticle => '아티클 추가';

  @override
  String get urlHint => 'URL을 입력하세요';

  @override
  String get invalidUrl => '유효하지 않은 URL입니다';

  @override
  String get pasteFromClipboard => '붙여넣기';

  @override
  String get swipeRead => '읽음';

  @override
  String get swipeLater => '나중에';
}
