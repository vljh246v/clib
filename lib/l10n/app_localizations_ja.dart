// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get save => '保存';

  @override
  String get saveFailed => '保存に失敗しました。もう一度お試しください。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get confirm => 'OK';

  @override
  String get add => '追加';

  @override
  String get edit => '編集';

  @override
  String get select => '選択';

  @override
  String get bookmark => 'ブックマーク';

  @override
  String get removeBookmark => 'ブックマーク解除';

  @override
  String get memo => 'メモ';

  @override
  String get editMemo => 'メモを編集';

  @override
  String get addMemo => 'メモを追加';

  @override
  String get memoHint => '短いメモを書く';

  @override
  String get label => 'ラベル';

  @override
  String get editLabelAction => 'ラベルを編集';

  @override
  String get labelManagement => 'ラベル管理';

  @override
  String get labelManagementSubtitle => 'ラベルの追加・編集・削除と通知設定';

  @override
  String get addNewLabel => '新しいラベルを追加';

  @override
  String get newLabel => '新しいラベル';

  @override
  String get addNewLabelTitle => '新しいラベルを追加';

  @override
  String get addLabelTitle => 'ラベルを追加';

  @override
  String get editLabelTitle => 'ラベルを編集';

  @override
  String get labelName => 'ラベル名';

  @override
  String get labelNameHint => '例: Flutter、デザイン';

  @override
  String get color => 'カラー';

  @override
  String get createLabelPrompt => 'ラベルを作成して記事を整理しましょう';

  @override
  String get addLabelsFirst => 'まず設定でラベルを追加してください';

  @override
  String get deleteLabel => 'ラベルを削除';

  @override
  String deleteLabelConfirm(String name, int count) {
    return '\'\'$name\'\' ラベルを削除しますか？\n$count件の記事からこのラベルが削除されます。';
  }

  @override
  String get allArticles => 'すべての記事';

  @override
  String articleCountText(int count) {
    return '$count件の記事';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count件の記事';
  }

  @override
  String get noArticles => '記事がありません。';

  @override
  String get noReadArticles => '既読の記事がありません。';

  @override
  String get noUnreadArticles => '未読の記事がありません。';

  @override
  String get deleteArticle => '記事を削除';

  @override
  String get deleteArticleConfirm => 'この記事を削除しますか？';

  @override
  String deleteSelectedConfirm(int count) {
    return '選択した$count件の記事を削除しますか？';
  }

  @override
  String selectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get read => '既読';

  @override
  String get unread => '未読';

  @override
  String get markAsRead => '既読にする';

  @override
  String get markAsUnread => '未読にする';

  @override
  String tabAll(int count) {
    return 'すべて ($count)';
  }

  @override
  String tabUnread(int count) {
    return '未読 ($count)';
  }

  @override
  String tabRead(int count) {
    return '既読 ($count)';
  }

  @override
  String totalAll(int count) {
    return '合計 $count';
  }

  @override
  String totalUnread(int count) {
    return '未読 $count';
  }

  @override
  String get library => 'ライブラリ';

  @override
  String get labelStatus => 'ラベル';

  @override
  String get overallReadingStatus => '全体の進捗';

  @override
  String articlesRead(int read, int total) {
    return '$total件中$read件読了';
  }

  @override
  String labelCount(int count) {
    return '$count個のラベル';
  }

  @override
  String get all => 'すべて';

  @override
  String get bookmarks => 'ブックマーク';

  @override
  String get noBookmarks => 'ブックマークした記事がありません。';

  @override
  String get noReadBookmarks => '既読のブックマークがありません。';

  @override
  String get noUnreadBookmarks => '未読のブックマークがありません。';

  @override
  String get noArticlesToSwipe => 'スワイプする記事がありません';

  @override
  String get addLinksHint => '他のアプリからリンクを共有して追加しましょう！';

  @override
  String get noUnreadInLabel => '選択したラベルに未読の記事がありません';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get settings => '設定';

  @override
  String get theme => 'テーマ';

  @override
  String get howToUse => '使い方';

  @override
  String get howToUseSubtitle => 'Clibの使い方を確認する';

  @override
  String get systemSettings => 'システム設定に従う';

  @override
  String get systemSettingsSubtitle => 'デバイスの設定に自動的に従います';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get onboardingSaveTitle => 'リンクを保存';

  @override
  String get onboardingSaveSubtitle => '共有ボタンひとつで\nどこからでも記事を収集';

  @override
  String get onboardingSaveHint => 'ブラウザ、SNS、YouTube → Clib';

  @override
  String get onboardingSwipeTitle => 'スワイプで読む';

  @override
  String get onboardingSwipeSubtitle => 'カードをめくって読むものを決める';

  @override
  String get onboardingSwipeHint => '右 → 既読  ·  左 → あとで読む';

  @override
  String get onboardingLibraryTitle => 'あなたのライブラリ';

  @override
  String get onboardingLibrarySubtitle => 'ラベルで整理、リマインダーで再訪';

  @override
  String get onboardingLibraryHint => '保存するだけから、実際に読むへ';

  @override
  String get skip => 'スキップ';

  @override
  String get next => '次へ';

  @override
  String get start => '始める';

  @override
  String labelNotification(String name) {
    return '$name の通知';
  }

  @override
  String get receiveNotification => '通知を受け取る';

  @override
  String get daysOfWeek => '曜日';

  @override
  String get selectTime => '時間を選択';

  @override
  String get time => '時間';

  @override
  String get notificationChannelName => 'Clib ラベル通知';

  @override
  String get notificationChannelDesc => 'ラベルごとの未読記事通知';

  @override
  String unreadNotification(int count) {
    return '未読の記事が$count件あります！';
  }

  @override
  String get allReadNotification => '全部読みました！ 🎉';

  @override
  String get dayMon => '月';

  @override
  String get dayTue => '火';

  @override
  String get dayWed => '水';

  @override
  String get dayThu => '木';

  @override
  String get dayFri => '金';

  @override
  String get daySat => '土';

  @override
  String get daySun => '日';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get saveToClib => 'Clibに保存';

  @override
  String get editArticle => '記事を編集';

  @override
  String get platform => 'プラットフォーム';

  @override
  String articleStats(int total, int read) {
    return '$total件の記事 · $read件読了';
  }

  @override
  String get account => 'アカウント';

  @override
  String get loginSubtitle => 'サインインしてデバイス間で同期';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get signInWithApple => 'Appleでサインイン';

  @override
  String get signOut => 'サインアウト';

  @override
  String get signOutConfirm => 'サインアウトしますか？';

  @override
  String get signOutDescription => 'このデバイスのデータは保持されます。';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountConfirm => 'アカウントを削除しますか？';

  @override
  String get deleteAccountDescription => 'クラウドデータはすべて削除されます。このデバイスのデータは保持されます。';

  @override
  String get syncComplete => '同期完了';

  @override
  String get syncing => '同期中...';

  @override
  String get loginFailed => 'サインインに失敗しました';

  @override
  String get notificationDeviceOnly => '通知はこのデバイスでのみ鳴ります。他のデバイスでは別途設定してください。';

  @override
  String get addArticle => '記事を追加';

  @override
  String get urlHint => 'URLを入力';

  @override
  String get invalidUrl => '無効なURL';

  @override
  String get pasteFromClipboard => '貼り付け';

  @override
  String get swipeRead => '既読';

  @override
  String get swipeLater => 'あとで';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get privacyPolicySubtitle => 'データの収集と管理';

  @override
  String get loginPolicyAgreement => 'サインインすると、プライバシーポリシーに同意したことになります。';

  @override
  String get guideSwipeTitle => 'スワイプで読もう';

  @override
  String get guideSwipeDesc => '右にスワイプで既読、左にスワイプであとで読む';

  @override
  String get guideAddTitle => '手動で追加もできます';

  @override
  String get guideAddDesc => 'URLを入力して記事を直接追加しましょう';

  @override
  String get guideLibraryTitle => 'ライブラリで管理';

  @override
  String get guideLibraryDesc => 'ラベルごとに整理された記事を確認・管理できます';

  @override
  String get guideSettingsTitle => '設定をカスタマイズ';

  @override
  String get guideSettingsDesc => 'ラベル管理、テーマ変更、リーディング通知を設定しましょう';

  @override
  String get guideTapToContinue => 'タップして続ける';
}
