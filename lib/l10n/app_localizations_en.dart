// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'OK';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get select => 'Select';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get removeBookmark => 'Remove Bookmark';

  @override
  String get memo => 'Memo';

  @override
  String get editMemo => 'Edit Memo';

  @override
  String get addMemo => 'Add Memo';

  @override
  String get memoHint => 'Write a short memo';

  @override
  String get label => 'Label';

  @override
  String get editLabelAction => 'Edit Labels';

  @override
  String get labelManagement => 'Manage Labels';

  @override
  String get labelManagementSubtitle =>
      'Add, edit, delete labels and set notifications';

  @override
  String get addNewLabel => 'Add New Label';

  @override
  String get newLabel => 'New Label';

  @override
  String get addNewLabelTitle => 'Add New Label';

  @override
  String get addLabelTitle => 'Add Label';

  @override
  String get editLabelTitle => 'Edit Label';

  @override
  String get labelName => 'Label Name';

  @override
  String get labelNameHint => 'e.g. Flutter, Design';

  @override
  String get color => 'Color';

  @override
  String get createLabelPrompt => 'Create labels to organize your articles';

  @override
  String get addLabelsFirst => 'Add labels in Settings first';

  @override
  String get deleteLabel => 'Delete Label';

  @override
  String deleteLabelConfirm(String name, int count) {
    return 'Delete \'\'$name\'\' label?\nThis label will be removed from $count articles.';
  }

  @override
  String get allArticles => 'All Articles';

  @override
  String articleCountText(int count) {
    return '$count articles';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count articles';
  }

  @override
  String get noArticles => 'No articles.';

  @override
  String get noReadArticles => 'No read articles.';

  @override
  String get noUnreadArticles => 'No unread articles.';

  @override
  String get deleteArticle => 'Delete Article';

  @override
  String get deleteArticleConfirm => 'Delete this article?';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Delete $count selected articles?';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get read => 'Read';

  @override
  String get unread => 'Unread';

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get markAsUnread => 'Mark as Unread';

  @override
  String tabAll(int count) {
    return 'All ($count)';
  }

  @override
  String tabUnread(int count) {
    return 'Unread ($count)';
  }

  @override
  String tabRead(int count) {
    return 'Read ($count)';
  }

  @override
  String totalAll(int count) {
    return 'Total $count';
  }

  @override
  String totalUnread(int count) {
    return 'Unread $count';
  }

  @override
  String get library => 'Library';

  @override
  String get labelStatus => 'Labels';

  @override
  String get overallReadingStatus => 'Overall Progress';

  @override
  String articlesRead(int read, int total) {
    return '$read / $total articles read';
  }

  @override
  String labelCount(int count) {
    return '$count labels';
  }

  @override
  String get all => 'All';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get noBookmarks => 'No bookmarked articles.';

  @override
  String get noReadBookmarks => 'No read bookmarks.';

  @override
  String get noUnreadBookmarks => 'No unread bookmarks.';

  @override
  String get noArticlesToSwipe => 'No articles to swipe';

  @override
  String get addLinksHint => 'Share links from other apps to add them!';

  @override
  String get noUnreadInLabel => 'No unread articles in selected labels';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get howToUse => 'How to Use';

  @override
  String get howToUseSubtitle => 'Review how to use Clib';

  @override
  String get systemSettings => 'System Default';

  @override
  String get systemSettingsSubtitle => 'Automatically follows device settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get onboardingSaveTitle => 'Save Your Links';

  @override
  String get onboardingSaveSubtitle =>
      'Collect articles from anywhere\nwith a single share button';

  @override
  String get onboardingSaveHint =>
      'Share from browser, social media, YouTube → Clib';

  @override
  String get onboardingSwipeTitle => 'Swipe to Read';

  @override
  String get onboardingSwipeSubtitle =>
      'Flip through cards to decide what to read';

  @override
  String get onboardingSwipeHint =>
      'Right → Mark as read  ·  Left → Read later';

  @override
  String get onboardingLibraryTitle => 'Your Personal Library';

  @override
  String get onboardingLibrarySubtitle =>
      'Organize with labels, revisit with reminders';

  @override
  String get onboardingLibraryHint => 'From saving to actually reading';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get start => 'Get Started';

  @override
  String labelNotification(String name) {
    return '$name Notifications';
  }

  @override
  String get receiveNotification => 'Enable Notifications';

  @override
  String get daysOfWeek => 'Days';

  @override
  String get selectTime => 'Select Time';

  @override
  String get time => 'Time';

  @override
  String get notificationChannelName => 'Clib Label Notifications';

  @override
  String get notificationChannelDesc => 'Unread article notifications by label';

  @override
  String unreadNotification(int count) {
    return 'You have $count unread articles!';
  }

  @override
  String get allReadNotification => 'All caught up! 🎉';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get saveToClib => 'Save to Clib';

  @override
  String get editArticle => 'Edit Article';

  @override
  String get platform => 'Platform';

  @override
  String articleStats(int total, int read) {
    return '$total articles · $read read';
  }

  @override
  String get account => 'Account';

  @override
  String get loginSubtitle => 'Sign in to sync across devices';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Sign out?';

  @override
  String get signOutDescription => 'Your data on this device will be kept.';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm => 'Delete your account?';

  @override
  String get deleteAccountDescription =>
      'All cloud data will be deleted. Data on this device will be kept.';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncing => 'Syncing...';

  @override
  String get loginFailed => 'Sign in failed';

  @override
  String get notificationDeviceOnly =>
      'Notifications only ring on this device. Set up separately on other devices.';
}
