import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/auth_service.dart';
import 'package:clib/services/sync_service.dart';

class DatabaseService {
  static const _boxName = 'articles';
  static const _labelBoxName = 'labels';
  static const _prefsBoxName = 'preferences';
  static const _channel = MethodChannel('com.jaehyun.clibapp/share');

  /// true일 때 Firestore 동기화를 건너뜀 (데모 데이터 시드 등)
  static bool skipSync = false;

  /// 테스트 전용 심(Seam): null이면 프로덕션 경로(SyncService.syncDeleteArticle)를 사용.
  /// 테스트에서 실패 시나리오를 주입하기 위해 사용한다.
  /// @visibleForTesting
  @visibleForTesting
  static Future<void> Function(Article)? syncDeleteOverride;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(PlatformAdapter());
    Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>(_boxName);
    await Hive.openBox<Label>(_labelBoxName);
    await Hive.openBox(_prefsBoxName);
  }

  static Box<Article> get _box => Hive.box<Article>(_boxName);
  static Box<Label> get _labelBox => Hive.box<Label>(_labelBoxName);
  static Box get _prefsBox => Hive.box(_prefsBoxName);

  // 마지막 로그인 UID (계정 전환 감지용)
  static String? get lastLoginUid =>
      _prefsBox.get('lastLoginUid') as String?;

  static Future<void> saveLastLoginUid(String? uid) async {
    if (uid == null) {
      await _prefsBox.delete('lastLoginUid');
    } else {
      await _prefsBox.put('lastLoginUid', uid);
    }
  }

  // 온보딩 완료 여부
  static bool get hasSeenOnboarding =>
      _prefsBox.get('hasSeenOnboarding', defaultValue: false) as bool;

  static Future<void> setOnboardingComplete() async {
    await _prefsBox.put('hasSeenOnboarding', true);
  }

  // 홈 오버레이 가이드 완료 여부
  static bool get hasSeenHomeGuide =>
      _prefsBox.get('hasSeenHomeGuide', defaultValue: false) as bool;

  static Future<void> setHomeGuideComplete() async {
    await _prefsBox.put('hasSeenHomeGuide', true);
  }

  // 테마 모드 저장/로드 (0=system, 1=light, 2=dark)
  static ThemeMode get savedThemeMode {
    final v = _prefsBox.get('themeMode', defaultValue: 0) as int;
    switch (v) {
      case 1: return ThemeMode.light;
      case 2: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final v = mode == ThemeMode.light ? 1 : mode == ThemeMode.dark ? 2 : 0;
    await _prefsBox.put('themeMode', v);
  }

  // 아티클 저장
  static Future<int> saveArticle(Article article) async {
    article.updatedAt = DateTime.now();
    final key = await _box.add(article);
    await _box.flush();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticle(article);
    }
    return key;
  }

  // 전체 아티클 목록
  static List<Article> getAllArticles() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // 전체 통계
  static ({int total, int read}) getOverallStats() {
    final all = _box.values.toList();
    return (total: all.length, read: all.where((a) => a.isRead).length);
  }

  // 미읽은 아티클 목록 (홈 스와이프용)
  static List<Article> getUnreadArticles() {
    return _box.values
        .where((a) => !a.isRead)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // 라벨별 아티클 목록
  static List<Article> getArticlesByLabel(String label) {
    return _box.values
        .where((a) => a.topicLabels.contains(label))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // 읽음 처리
  static Future<void> markAsRead(Article article) async {
    article.isRead = true;
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(article, {'isRead': true});
    }
  }

  // 안 읽음 처리
  static Future<void> markAsUnread(Article article) async {
    article.isRead = false;
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(article, {'isRead': false});
    }
  }

  // 일괄 읽음/안읽음 처리 (batch write로 스냅샷 1회)
  static Future<void> bulkMarkRead(List<Article> articles, bool isRead) async {
    final now = DateTime.now();
    for (final article in articles) {
      article.isRead = isRead;
      article.updatedAt = now;
      await article.save();
    }
    await _box.flush();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncBulkArticleFields(articles, {'isRead': isRead});
    }
  }

  // 일괄 북마크 설정 (batch write로 스냅샷 1회)
  static Future<void> bulkSetBookmark(List<Article> articles, bool bookmark) async {
    final now = DateTime.now();
    for (final article in articles) {
      article.isBookmarked = bookmark;
      article.updatedAt = now;
      await article.save();
    }
    await _box.flush();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncBulkArticleFields(
          articles, {'isBookmarked': bookmark});
    }
  }

  // 북마크 토글
  static Future<void> toggleBookmark(Article article) async {
    article.isBookmarked = !article.isBookmarked;
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(
          article, {'isBookmarked': article.isBookmarked});
    }
  }

  // 메모 업데이트
  static Future<void> updateMemo(Article article, String? memo) async {
    article.memo = (memo != null && memo.trim().isEmpty) ? null : memo?.trim();
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(article, {'memo': article.memo});
    }
  }

  // 북마크된 아티클 목록
  static List<Article> getBookmarkedArticles() {
    return _box.values
        .where((a) => a.isBookmarked)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // 북마크 통계
  static ({int total, int read}) getBookmarkStats() {
    final articles = _box.values.where((a) => a.isBookmarked).toList();
    return (total: articles.length, read: articles.where((a) => a.isRead).length);
  }

  // 아티클 삭제
  // Firestore 동기화 실패 시 로컬 Hive 엔트리를 보존하고 예외를 전파한다 (H-1).
  // TODO: 호출자(UI)에서 이 예외를 받아 사용자에게 안내 메시지를 표시해야 한다.
  static Future<void> deleteArticle(Article article) async {
    final overrideFn = syncDeleteOverride;
    if (overrideFn != null) {
      // 테스트 경로: 오버라이드 함수 호출 (실패 시 rethrow → 로컬 삭제 차단)
      await overrideFn(article);
    } else if (!skipSync && AuthService.isLoggedIn) {
      // 프로덕션 경로: Firestore softDelete 실패 시 rethrow → 로컬 삭제 차단
      await SyncService.syncDeleteArticle(article);
    }
    await article.delete();
  }

  // 모든 라벨 목록
  static List<String> getAllLabels() {
    final labels = <String>{};
    for (final article in _box.values) {
      labels.addAll(article.topicLabels);
    }
    return labels.toList()..sort();
  }

  // 라벨별 통계
  static ({int total, int read}) getLabelStats(String label) {
    final articles = _box.values
        .where((a) => a.topicLabels.contains(label))
        .toList();
    final read = articles.where((a) => a.isRead).length;
    return (total: articles.length, read: read);
  }

  // ── 라벨 CRUD ──

  // 라벨 전체 목록
  static List<Label> getAllLabelObjects() {
    return _labelBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // 라벨 생성
  static Future<Label> createLabel(String name, Color color) async {
    final exists = _labelBox.values.any(
      (l) => l.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) throw Exception('이미 존재하는 라벨입니다: $name');

    final label = Label()
      ..name = name
      ..colorValue = color.toARGB32()
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await _labelBox.add(label);
    await _labelBox.flush();
    await syncLabelsToAppGroup();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncLabel(label);
    }
    return label;
  }

  // 라벨 수정
  static Future<void> updateLabel(
    Label label, {
    String? newName,
    Color? newColor,
  }) async {
    final oldName = label.name;

    if (newName != null && newName != oldName) {
      // 중복 체크
      final exists = _labelBox.values.any(
        (l) => l.key != label.key && l.name.toLowerCase() == newName.toLowerCase(),
      );
      if (exists) throw Exception('이미 존재하는 라벨입니다: $newName');

      // 모든 아티클의 라벨명 일괄 업데이트
      for (final article in _box.values) {
        final idx = article.topicLabels.indexOf(oldName);
        if (idx != -1) {
          article.topicLabels[idx] = newName;
          article.updatedAt = DateTime.now();
          await article.save();
          if (!skipSync && AuthService.isLoggedIn) {
            await SyncService.syncArticleFields(
                article, {'topicLabels': article.topicLabels});
          }
        }
      }
      label.name = newName;
    }

    if (newColor != null) {
      label.colorValue = newColor.toARGB32();
    }

    label.updatedAt = DateTime.now();
    await label.save();
    await syncLabelsToAppGroup();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncLabel(label);
    }
  }

  // 라벨 삭제
  static Future<void> deleteLabel(Label label) async {
    // 모든 아티클에서 해당 라벨 제거
    for (final article in _box.values) {
      if (article.topicLabels.remove(label.name)) {
        article.updatedAt = DateTime.now();
        await article.save();
        if (!skipSync && AuthService.isLoggedIn) {
          await SyncService.syncArticleFields(
              article, {'topicLabels': article.topicLabels});
        }
      }
    }
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncDeleteLabel(label);
    }
    await label.delete();
    await syncLabelsToAppGroup();
  }

  // iOS Share Extension용 라벨 동기화
  static Future<void> syncLabelsToAppGroup() async {
    if (!io.Platform.isIOS) return;
    try {
      final payload = _labelBox.values
          .map((l) => {'name': l.name, 'colorValue': l.colorValue})
          .toList();
      await _channel.invokeMethod('syncLabels', payload);
    } on PlatformException {
      // 무시
    }
  }

  // 라벨 이름으로 Label 객체 찾기
  static Label? getLabelByName(String name) {
    try {
      return _labelBox.values.firstWhere(
        (l) => l.name == name,
      );
    } catch (_) {
      return null;
    }
  }

  // ── 라벨 알림 설정 ──

  // 라벨 알림 설정 저장
  static Future<void> updateLabelNotification(
    Label label, {
    required bool enabled,
    required List<int> days,
    required String time,
  }) async {
    label.notificationEnabled = enabled;
    label.notificationDays = days;
    label.notificationTime = time;
    await label.save();
  }

  // 알림 활성 라벨 목록
  static List<Label> getLabelsWithNotification() {
    return _labelBox.values
        .where((l) => l.notificationEnabled && l.notificationDays.isNotEmpty)
        .toList();
  }

  // 아티클의 라벨 업데이트
  static Future<void> updateArticleLabels(
    Article article,
    List<String> newLabels,
  ) async {
    article.topicLabels = newLabels;
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(
          article, {'topicLabels': newLabels});
    }
  }
}
