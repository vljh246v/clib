// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get save => '保存';

  @override
  String get saveFailed => '保存失败，请重试。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确定';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get select => '选择';

  @override
  String get bookmark => '收藏';

  @override
  String get removeBookmark => '取消收藏';

  @override
  String get memo => '备注';

  @override
  String get editMemo => '编辑备注';

  @override
  String get addMemo => '添加备注';

  @override
  String get memoHint => '写一条简短备注';

  @override
  String get label => '标签';

  @override
  String get editLabelAction => '编辑标签';

  @override
  String get labelManagement => '标签管理';

  @override
  String get labelManagementSubtitle => '添加、编辑、删除标签并设置提醒';

  @override
  String get addNewLabel => '新建标签';

  @override
  String get newLabel => '新标签';

  @override
  String get addNewLabelTitle => '新建标签';

  @override
  String get addLabelTitle => '添加标签';

  @override
  String get editLabelTitle => '编辑标签';

  @override
  String get labelName => '标签名称';

  @override
  String get labelNameHint => '如 Flutter、设计';

  @override
  String get color => '颜色';

  @override
  String get createLabelPrompt => '创建标签来整理你的文章';

  @override
  String get addLabelsFirst => '请先在设置中添加标签';

  @override
  String get deleteLabel => '删除标签';

  @override
  String deleteLabelConfirm(String name, int count) {
    return '确定删除「$name」标签吗？\n将从 $count 篇文章中移除该标签。';
  }

  @override
  String get allArticles => '全部文章';

  @override
  String articleCountText(int count) {
    return '$count 篇文章';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count 篇文章';
  }

  @override
  String get noArticles => '还没有文章。';

  @override
  String get noReadArticles => '没有已读文章。';

  @override
  String get noUnreadArticles => '没有未读文章。';

  @override
  String get deleteArticle => '删除文章';

  @override
  String get deleteArticleConfirm => '确定删除这篇文章吗？';

  @override
  String deleteSelectedConfirm(int count) {
    return '确定删除选中的 $count 篇文章吗？';
  }

  @override
  String selectedCount(int count) {
    return '已选 $count 篇';
  }

  @override
  String get read => '已读';

  @override
  String get unread => '未读';

  @override
  String get markAsRead => '标为已读';

  @override
  String get markAsUnread => '标为未读';

  @override
  String tabAll(int count) {
    return '全部 ($count)';
  }

  @override
  String tabUnread(int count) {
    return '未读 ($count)';
  }

  @override
  String tabRead(int count) {
    return '已读 ($count)';
  }

  @override
  String totalAll(int count) {
    return '共 $count 篇';
  }

  @override
  String totalUnread(int count) {
    return '未读 $count 篇';
  }

  @override
  String get library => '书架';

  @override
  String get labelStatus => '标签';

  @override
  String get overallReadingStatus => '阅读进度';

  @override
  String articlesRead(int read, int total) {
    return '已读 $read / $total 篇';
  }

  @override
  String labelCount(int count) {
    return '$count 个标签';
  }

  @override
  String get all => '全部';

  @override
  String get bookmarks => '收藏夹';

  @override
  String get noBookmarks => '还没有收藏的文章。';

  @override
  String get noReadBookmarks => '没有已读的收藏。';

  @override
  String get noUnreadBookmarks => '没有未读的收藏。';

  @override
  String get noArticlesToSwipe => '没有可以滑动的文章';

  @override
  String get addLinksHint => '从其他应用分享链接来添加文章吧！';

  @override
  String get noUnreadInLabel => '所选标签下没有未读文章';

  @override
  String get openInBrowser => '用浏览器打开';

  @override
  String get settings => '设置';

  @override
  String get theme => '主题';

  @override
  String get howToUse => '使用指南';

  @override
  String get howToUseSubtitle => '了解如何使用 Clib';

  @override
  String get systemSettings => '跟随系统';

  @override
  String get systemSettingsSubtitle => '自动跟随设备的显示设置';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get onboardingSaveTitle => '保存你的链接';

  @override
  String get onboardingSaveSubtitle => '一键分享\n随时随地收集好文章';

  @override
  String get onboardingSaveHint => '从浏览器、社交媒体、YouTube 分享 → Clib';

  @override
  String get onboardingSwipeTitle => '滑动阅读';

  @override
  String get onboardingSwipeSubtitle => '翻动卡片，决定先读哪篇';

  @override
  String get onboardingSwipeHint => '右滑 → 标为已读  ·  左滑 → 稍后再看';

  @override
  String get onboardingLibraryTitle => '你的私人书架';

  @override
  String get onboardingLibrarySubtitle => '用标签整理，用提醒回顾';

  @override
  String get onboardingLibraryHint => '从只收藏到真正读完';

  @override
  String get skip => '跳过';

  @override
  String get next => '下一步';

  @override
  String get start => '开始使用';

  @override
  String labelNotification(String name) {
    return '「$name」提醒';
  }

  @override
  String get receiveNotification => '开启提醒';

  @override
  String get daysOfWeek => '重复日';

  @override
  String get selectTime => '选择时间';

  @override
  String get time => '时间';

  @override
  String get notificationChannelName => 'Clib 标签提醒';

  @override
  String get notificationChannelDesc => '按标签提醒未读文章';

  @override
  String unreadNotification(int count) {
    return '还有 $count 篇没读，快来看看！';
  }

  @override
  String get allReadNotification => '全部读完了！🎉';

  @override
  String get dayMon => '一';

  @override
  String get dayTue => '二';

  @override
  String get dayWed => '三';

  @override
  String get dayThu => '四';

  @override
  String get dayFri => '五';

  @override
  String get daySat => '六';

  @override
  String get daySun => '日';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get saveToClib => '保存到 Clib';

  @override
  String get editArticle => '编辑文章';

  @override
  String get platform => '平台';

  @override
  String articleStats(int total, int read) {
    return '$total 篇文章 · 已读 $read 篇';
  }

  @override
  String get account => '账号';

  @override
  String get loginSubtitle => '登录后可跨设备同步';

  @override
  String get signInWithGoogle => '用 Google 登录';

  @override
  String get signInWithApple => '用 Apple 登录';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirm => '确定退出登录吗？';

  @override
  String get signOutDescription => '本设备上的数据会保留。';

  @override
  String get deleteAccount => '注销账号';

  @override
  String get deleteAccountConfirm => '确定注销账号吗？';

  @override
  String get deleteAccountDescription => '云端数据将被全部删除。本设备上的数据会保留。';

  @override
  String get syncComplete => '同步完成';

  @override
  String get syncing => '同步中…';

  @override
  String get loginFailed => '登录失败';

  @override
  String get notificationDeviceOnly => '提醒仅在当前设备上生效，其他设备需单独设置。';

  @override
  String get addArticle => '添加文章';

  @override
  String get urlHint => '输入链接';

  @override
  String get invalidUrl => '链接格式不正确';

  @override
  String get pasteFromClipboard => '粘贴';

  @override
  String get swipeRead => '已读';

  @override
  String get swipeLater => '稍后';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicySubtitle => '数据收集与管理';

  @override
  String get loginPolicyAgreement => '登录即表示你同意隐私政策。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get save => '保存';

  @override
  String get saveFailed => '保存失败，请重试。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确定';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get select => '选择';

  @override
  String get bookmark => '收藏';

  @override
  String get removeBookmark => '取消收藏';

  @override
  String get memo => '备注';

  @override
  String get editMemo => '编辑备注';

  @override
  String get addMemo => '添加备注';

  @override
  String get memoHint => '写一条简短备注';

  @override
  String get label => '标签';

  @override
  String get editLabelAction => '编辑标签';

  @override
  String get labelManagement => '标签管理';

  @override
  String get labelManagementSubtitle => '添加、编辑、删除标签并设置提醒';

  @override
  String get addNewLabel => '新建标签';

  @override
  String get newLabel => '新标签';

  @override
  String get addNewLabelTitle => '新建标签';

  @override
  String get addLabelTitle => '添加标签';

  @override
  String get editLabelTitle => '编辑标签';

  @override
  String get labelName => '标签名称';

  @override
  String get labelNameHint => '如 Flutter、设计';

  @override
  String get color => '颜色';

  @override
  String get createLabelPrompt => '创建标签来整理你的文章';

  @override
  String get addLabelsFirst => '请先在设置中添加标签';

  @override
  String get deleteLabel => '删除标签';

  @override
  String deleteLabelConfirm(String name, int count) {
    return '确定删除「$name」标签吗？\n将从 $count 篇文章中移除该标签。';
  }

  @override
  String get allArticles => '全部文章';

  @override
  String articleCountText(int count) {
    return '$count 篇文章';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count 篇文章';
  }

  @override
  String get noArticles => '还没有文章。';

  @override
  String get noReadArticles => '没有已读文章。';

  @override
  String get noUnreadArticles => '没有未读文章。';

  @override
  String get deleteArticle => '删除文章';

  @override
  String get deleteArticleConfirm => '确定删除这篇文章吗？';

  @override
  String deleteSelectedConfirm(int count) {
    return '确定删除选中的 $count 篇文章吗？';
  }

  @override
  String selectedCount(int count) {
    return '已选 $count 篇';
  }

  @override
  String get read => '已读';

  @override
  String get unread => '未读';

  @override
  String get markAsRead => '标为已读';

  @override
  String get markAsUnread => '标为未读';

  @override
  String tabAll(int count) {
    return '全部 ($count)';
  }

  @override
  String tabUnread(int count) {
    return '未读 ($count)';
  }

  @override
  String tabRead(int count) {
    return '已读 ($count)';
  }

  @override
  String totalAll(int count) {
    return '共 $count 篇';
  }

  @override
  String totalUnread(int count) {
    return '未读 $count 篇';
  }

  @override
  String get library => '书架';

  @override
  String get labelStatus => '标签';

  @override
  String get overallReadingStatus => '阅读进度';

  @override
  String articlesRead(int read, int total) {
    return '已读 $read / $total 篇';
  }

  @override
  String labelCount(int count) {
    return '$count 个标签';
  }

  @override
  String get all => '全部';

  @override
  String get bookmarks => '收藏夹';

  @override
  String get noBookmarks => '还没有收藏的文章。';

  @override
  String get noReadBookmarks => '没有已读的收藏。';

  @override
  String get noUnreadBookmarks => '没有未读的收藏。';

  @override
  String get noArticlesToSwipe => '没有可以滑动的文章';

  @override
  String get addLinksHint => '从其他应用分享链接来添加文章吧！';

  @override
  String get noUnreadInLabel => '所选标签下没有未读文章';

  @override
  String get openInBrowser => '用浏览器打开';

  @override
  String get settings => '设置';

  @override
  String get theme => '主题';

  @override
  String get howToUse => '使用指南';

  @override
  String get howToUseSubtitle => '了解如何使用 Clib';

  @override
  String get systemSettings => '跟随系统';

  @override
  String get systemSettingsSubtitle => '自动跟随设备的显示设置';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get onboardingSaveTitle => '保存你的链接';

  @override
  String get onboardingSaveSubtitle => '一键分享\n随时随地收集好文章';

  @override
  String get onboardingSaveHint => '从浏览器、社交媒体、YouTube 分享 → Clib';

  @override
  String get onboardingSwipeTitle => '滑动阅读';

  @override
  String get onboardingSwipeSubtitle => '翻动卡片，决定先读哪篇';

  @override
  String get onboardingSwipeHint => '右滑 → 标为已读  ·  左滑 → 稍后再看';

  @override
  String get onboardingLibraryTitle => '你的私人书架';

  @override
  String get onboardingLibrarySubtitle => '用标签整理，用提醒回顾';

  @override
  String get onboardingLibraryHint => '从只收藏到真正读完';

  @override
  String get skip => '跳过';

  @override
  String get next => '下一步';

  @override
  String get start => '开始使用';

  @override
  String labelNotification(String name) {
    return '「$name」提醒';
  }

  @override
  String get receiveNotification => '开启提醒';

  @override
  String get daysOfWeek => '重复日';

  @override
  String get selectTime => '选择时间';

  @override
  String get time => '时间';

  @override
  String get notificationChannelName => 'Clib 标签提醒';

  @override
  String get notificationChannelDesc => '按标签提醒未读文章';

  @override
  String unreadNotification(int count) {
    return '还有 $count 篇没读，快来看看！';
  }

  @override
  String get allReadNotification => '全部读完了！🎉';

  @override
  String get dayMon => '一';

  @override
  String get dayTue => '二';

  @override
  String get dayWed => '三';

  @override
  String get dayThu => '四';

  @override
  String get dayFri => '五';

  @override
  String get daySat => '六';

  @override
  String get daySun => '日';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get saveToClib => '保存到 Clib';

  @override
  String get editArticle => '编辑文章';

  @override
  String get platform => '平台';

  @override
  String articleStats(int total, int read) {
    return '$total 篇文章 · 已读 $read 篇';
  }

  @override
  String get account => '账号';

  @override
  String get loginSubtitle => '登录后可跨设备同步';

  @override
  String get signInWithGoogle => '用 Google 登录';

  @override
  String get signInWithApple => '用 Apple 登录';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirm => '确定退出登录吗？';

  @override
  String get signOutDescription => '本设备上的数据会保留。';

  @override
  String get deleteAccount => '注销账号';

  @override
  String get deleteAccountConfirm => '确定注销账号吗？';

  @override
  String get deleteAccountDescription => '云端数据将被全部删除。本设备上的数据会保留。';

  @override
  String get syncComplete => '同步完成';

  @override
  String get syncing => '同步中…';

  @override
  String get loginFailed => '登录失败';

  @override
  String get notificationDeviceOnly => '提醒仅在当前设备上生效，其他设备需单独设置。';

  @override
  String get addArticle => '添加文章';

  @override
  String get urlHint => '输入链接';

  @override
  String get invalidUrl => '链接格式不正确';

  @override
  String get pasteFromClipboard => '粘贴';

  @override
  String get swipeRead => '已读';

  @override
  String get swipeLater => '稍后';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicySubtitle => '数据收集与管理';

  @override
  String get loginPolicyAgreement => '登录即表示你同意隐私政策。';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get save => '儲存';

  @override
  String get saveFailed => '儲存失敗，請再試一次。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get confirm => '確定';

  @override
  String get add => '新增';

  @override
  String get edit => '編輯';

  @override
  String get select => '選取';

  @override
  String get bookmark => '書籤';

  @override
  String get removeBookmark => '移除書籤';

  @override
  String get memo => '備忘';

  @override
  String get editMemo => '編輯備忘';

  @override
  String get addMemo => '新增備忘';

  @override
  String get memoHint => '寫一段簡短備忘';

  @override
  String get label => '標籤';

  @override
  String get editLabelAction => '編輯標籤';

  @override
  String get labelManagement => '標籤管理';

  @override
  String get labelManagementSubtitle => '新增、編輯、刪除標籤與通知設定';

  @override
  String get addNewLabel => '新增標籤';

  @override
  String get newLabel => '新標籤';

  @override
  String get addNewLabelTitle => '新增標籤';

  @override
  String get addLabelTitle => '新增標籤';

  @override
  String get editLabelTitle => '編輯標籤';

  @override
  String get labelName => '標籤名稱';

  @override
  String get labelNameHint => '例如 Flutter、設計';

  @override
  String get color => '顏色';

  @override
  String get createLabelPrompt => '建立標籤來整理你的文章';

  @override
  String get addLabelsFirst => '請先到設定新增標籤';

  @override
  String get deleteLabel => '刪除標籤';

  @override
  String deleteLabelConfirm(String name, int count) {
    return '確定刪除「$name」標籤嗎？\n將會從 $count 篇文章中移除。';
  }

  @override
  String get allArticles => '所有文章';

  @override
  String articleCountText(int count) {
    return '$count 篇文章';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels・$count 篇文章';
  }

  @override
  String get noArticles => '還沒有文章。';

  @override
  String get noReadArticles => '沒有已讀文章。';

  @override
  String get noUnreadArticles => '沒有未讀文章。';

  @override
  String get deleteArticle => '刪除文章';

  @override
  String get deleteArticleConfirm => '確定刪除這篇文章嗎？';

  @override
  String deleteSelectedConfirm(int count) {
    return '確定刪除選取的 $count 篇文章嗎？';
  }

  @override
  String selectedCount(int count) {
    return '已選 $count 篇';
  }

  @override
  String get read => '已讀';

  @override
  String get unread => '未讀';

  @override
  String get markAsRead => '標為已讀';

  @override
  String get markAsUnread => '標為未讀';

  @override
  String tabAll(int count) {
    return '全部 ($count)';
  }

  @override
  String tabUnread(int count) {
    return '未讀 ($count)';
  }

  @override
  String tabRead(int count) {
    return '已讀 ($count)';
  }

  @override
  String totalAll(int count) {
    return '共 $count 篇';
  }

  @override
  String totalUnread(int count) {
    return '未讀 $count 篇';
  }

  @override
  String get library => '書架';

  @override
  String get labelStatus => '標籤';

  @override
  String get overallReadingStatus => '閱讀進度';

  @override
  String articlesRead(int read, int total) {
    return '已讀 $read / $total 篇';
  }

  @override
  String labelCount(int count) {
    return '$count 個標籤';
  }

  @override
  String get all => '全部';

  @override
  String get bookmarks => '書籤';

  @override
  String get noBookmarks => '還沒有加入書籤的文章。';

  @override
  String get noReadBookmarks => '沒有已讀的書籤。';

  @override
  String get noUnreadBookmarks => '沒有未讀的書籤。';

  @override
  String get noArticlesToSwipe => '沒有可以滑動的文章';

  @override
  String get addLinksHint => '從其他 App 分享連結來新增文章吧！';

  @override
  String get noUnreadInLabel => '所選標籤中沒有未讀文章';

  @override
  String get openInBrowser => '在瀏覽器中開啟';

  @override
  String get settings => '設定';

  @override
  String get theme => '主題';

  @override
  String get howToUse => '使用方式';

  @override
  String get howToUseSubtitle => '瞭解如何使用 Clib';

  @override
  String get systemSettings => '跟隨系統';

  @override
  String get systemSettingsSubtitle => '自動跟隨裝置的顯示設定';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '淺色模式';

  @override
  String get onboardingSaveTitle => '儲存你的連結';

  @override
  String get onboardingSaveSubtitle => '只要按一下分享\n隨時隨地收集好文章';

  @override
  String get onboardingSaveHint => '從瀏覽器、社群媒體、YouTube 分享 → Clib';

  @override
  String get onboardingSwipeTitle => '滑動閱讀';

  @override
  String get onboardingSwipeSubtitle => '翻動卡片，決定先讀哪篇';

  @override
  String get onboardingSwipeHint => '右滑 → 標為已讀  ·  左滑 → 稍後再看';

  @override
  String get onboardingLibraryTitle => '你的私人書架';

  @override
  String get onboardingLibrarySubtitle => '用標籤整理，用提醒回顧';

  @override
  String get onboardingLibraryHint => '從只收藏到真正讀完';

  @override
  String get skip => '略過';

  @override
  String get next => '下一步';

  @override
  String get start => '開始使用';

  @override
  String labelNotification(String name) {
    return '「$name」通知';
  }

  @override
  String get receiveNotification => '開啟通知';

  @override
  String get daysOfWeek => '重複日';

  @override
  String get selectTime => '選擇時間';

  @override
  String get time => '時間';

  @override
  String get notificationChannelName => 'Clib 標籤通知';

  @override
  String get notificationChannelDesc => '依標籤提醒未讀文章';

  @override
  String unreadNotification(int count) {
    return '還有 $count 篇沒讀，快來看看！';
  }

  @override
  String get allReadNotification => '全部讀完了！🎉';

  @override
  String get dayMon => '一';

  @override
  String get dayTue => '二';

  @override
  String get dayWed => '三';

  @override
  String get dayThu => '四';

  @override
  String get dayFri => '五';

  @override
  String get daySat => '六';

  @override
  String get daySun => '日';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get saveToClib => '儲存到 Clib';

  @override
  String get editArticle => '編輯文章';

  @override
  String get platform => '平台';

  @override
  String articleStats(int total, int read) {
    return '$total 篇文章・已讀 $read 篇';
  }

  @override
  String get account => '帳號';

  @override
  String get loginSubtitle => '登入後可跨裝置同步';

  @override
  String get signInWithGoogle => '以 Google 登入';

  @override
  String get signInWithApple => '以 Apple 登入';

  @override
  String get signOut => '登出';

  @override
  String get signOutConfirm => '確定要登出嗎？';

  @override
  String get signOutDescription => '這台裝置上的資料會保留。';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get deleteAccountConfirm => '確定刪除帳號嗎？';

  @override
  String get deleteAccountDescription => '雲端資料將會全部刪除。這台裝置上的資料會保留。';

  @override
  String get syncComplete => '同步完成';

  @override
  String get syncing => '同步中…';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get notificationDeviceOnly => '通知僅在目前裝置上生效，其他裝置需另外設定。';

  @override
  String get addArticle => '新增文章';

  @override
  String get urlHint => '輸入網址';

  @override
  String get invalidUrl => '網址格式不正確';

  @override
  String get pasteFromClipboard => '貼上';

  @override
  String get swipeRead => '已讀';

  @override
  String get swipeLater => '稍後';

  @override
  String get privacyPolicy => '隱私權政策';

  @override
  String get privacyPolicySubtitle => '資料收集與管理';

  @override
  String get loginPolicyAgreement => '登入即表示你同意隱私權政策。';
}
