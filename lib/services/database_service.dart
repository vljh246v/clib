import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/auth_service.dart';
import 'package:clib/services/hive_cipher_service.dart';
import 'package:clib/services/sync_service.dart';
import 'package:clib/state/app_notifiers.dart';
import 'package:clib/utils/app_logger.dart';

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

  /// 앱 초기화. Hive를 열고, 필요 시 평문 → AES 암호화 마이그레이션을 수행한다.
  ///
  /// [forTest] 가 `true`이면 마이그레이션을 건너뛰고 평문 박스를 그대로 연다.
  /// 단위·통합 테스트는 반드시 `forTest: true`로 호출할 것.
  ///
  /// ### 마이그레이션 전략
  /// preferences 박스의 `hive_encrypted_v1` 플래그로 암호화 여부를 추적한다.
  ///
  /// - **플래그 = true** (기존 설치·마이그레이션 완료): 암호화 키로 박스를 열기만 한다.
  /// - **플래그 = false/미설정** (평문 박스 존재): 평문 읽기 → 박스 삭제 → 암호화 재오픈 → 쓰기.
  ///
  /// #### 프로세스 강제 종료 시 안전성
  /// 마이그레이션은 `deleteBoxFromDisk` → 암호화 재오픈 → 쓰기 순서로 진행된다.
  /// 이 구간에서 OS가 프로세스를 종료하면 평문 박스는 이미 삭제된 상태이고
  /// 플래그도 `false`이므로 다음 부팅에서 마이그레이션이 다시 시도된다.
  /// 이때 빈 박스가 암호화되어 열리므로 **마이그레이션 구간 내 강제 종료 시
  /// 해당 구간에 쓰지 못한 아티클/라벨 데이터는 손실된다.**
  /// 이 창(window)은 통상 1초 미만이며, 앱 시작 시 주로 발생한다.
  ///
  /// #### preferences 박스
  /// preferences 박스는 마이그레이션 플래그를 보관하기 위해 평문으로 유지한다.
  /// 평문 암호화하면 닭-달걀 문제가 발생한다.
  static Future<void> init({bool forTest = false}) async {
    await Hive.initFlutter();
    // 어댑터는 프로세스 내 싱글톤 — 중복 등록 방지
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());

    // preferences 박스는 마이그레이션 플래그 보관용으로 평문 유지
    await Hive.openBox(_prefsBoxName);

    if (forTest) {
      // 테스트 경로: 마이그레이션 없이 평문 박스 오픈
      await Hive.openBox<Article>(_boxName);
      await Hive.openBox<Label>(_labelBoxName);
      return;
    }

    // 프로덕션 경로: AES 암호화 마이그레이션
    final alreadyEncrypted =
        _prefsBox.get('hive_encrypted_v1', defaultValue: false) as bool;

    if (alreadyEncrypted) {
      // 이미 암호화된 박스 — 키를 가져와 열기만 한다
      final cipher = await HiveCipherService.getCipher();
      await Hive.openBox<Article>(_boxName, encryptionCipher: cipher);
      await Hive.openBox<Label>(_labelBoxName, encryptionCipher: cipher);
    } else {
      // 평문 → 암호화 마이그레이션
      await _migrateToEncrypted();
    }
  }

  /// 평문 Hive 박스를 AES 암호화 박스로 마이그레이션한다.
  ///
  /// 실패 시 평문 박스를 다시 열어 데이터를 보존하고 플래그를 false로 유지한다.
  /// 다음 부팅에서 재시도한다.
  static Future<void> _migrateToEncrypted() async {
    try {
      await _migrateBoxesForTest(cipher: await HiveCipherService.getCipher());
    } catch (e, st) {
      logError('Hive 암호화 마이그레이션 실패 — 평문 폴백', e, st);
      // 박스가 닫혀 있을 수 있으므로 안전하게 다시 열기 시도
      try {
        if (!Hive.isBoxOpen(_boxName)) {
          await Hive.openBox<Article>(_boxName);
        }
        if (!Hive.isBoxOpen(_labelBoxName)) {
          await Hive.openBox<Label>(_labelBoxName);
        }
      } catch (reopenError, reopenSt) {
        logError('평문 폴백 재오픈 실패', reopenError, reopenSt);
      }
      // 플래그를 false로 유지 → 다음 실행에서 재시도
    }
  }

  /// 암호화 마이그레이션 핵심 로직.
  ///
  /// [cipher]를 외부에서 주입받아 FlutterSecureStorage 없이 단위 테스트 가능하다.
  /// `@visibleForTesting` 으로 표시 — 프로덕션 코드는 `_migrateToEncrypted()`를 사용할 것.
  @visibleForTesting
  static Future<void> migrateBoxesForTest({
    required HiveAesCipher cipher,
  }) async {
    await _migrateBoxesForTest(cipher: cipher);
  }

  static Future<void> _migrateBoxesForTest({
    required HiveAesCipher cipher,
  }) async {
    // 1. 평문 박스 열기 (이미 열려 있으면 재사용)
    final Box<Article> plainArticles = Hive.isBoxOpen(_boxName)
        ? Hive.box<Article>(_boxName)
        : await Hive.openBox<Article>(_boxName);
    final Box<Label> plainLabels = Hive.isBoxOpen(_labelBoxName)
        ? Hive.box<Label>(_labelBoxName)
        : await Hive.openBox<Label>(_labelBoxName);

    // 2. 평문 데이터 메모리에 읽기
    final articleEntries = {
      for (final key in plainArticles.keys)
        key as dynamic: plainArticles.get(key)!
    };
    final labelEntries = {
      for (final key in plainLabels.keys)
        key as dynamic: plainLabels.get(key)!
    };

    // 3. 평문 박스 닫기 + 디스크에서 삭제
    await plainArticles.close();
    await plainLabels.close();
    await Hive.deleteBoxFromDisk(_boxName);
    await Hive.deleteBoxFromDisk(_labelBoxName);

    // 4. 암호화 박스 오픈
    final encArticles = await Hive.openBox<Article>(
      _boxName,
      encryptionCipher: cipher,
    );
    final encLabels = await Hive.openBox<Label>(
      _labelBoxName,
      encryptionCipher: cipher,
    );

    // 5. 데이터 복원 — HiveObject는 동일 인스턴스가 두 박스에 속할 수 없으므로
    //    필드 복사로 새 인스턴스를 만들어 저장한다.
    final clonedArticles = <dynamic, Article>{
      for (final e in articleEntries.entries)
        e.key: (Article()
          ..url = e.value.url
          ..title = e.value.title
          ..thumbnailUrl = e.value.thumbnailUrl
          ..platform = e.value.platform
          ..topicLabels = List<String>.from(e.value.topicLabels)
          ..isRead = e.value.isRead
          ..createdAt = e.value.createdAt
          ..isBookmarked = e.value.isBookmarked
          ..memo = e.value.memo
          ..firestoreId = e.value.firestoreId
          ..updatedAt = e.value.updatedAt
          ..deletedAt = e.value.deletedAt),
    };
    final clonedLabels = <dynamic, Label>{
      for (final e in labelEntries.entries)
        e.key: (Label()
          ..name = e.value.name
          ..colorValue = e.value.colorValue
          ..createdAt = e.value.createdAt
          ..notificationEnabled = e.value.notificationEnabled
          ..notificationDays = List<int>.from(e.value.notificationDays)
          ..notificationTime = e.value.notificationTime
          ..firestoreId = e.value.firestoreId
          ..updatedAt = e.value.updatedAt
          ..deletedAt = e.value.deletedAt),
    };
    await encArticles.putAll(clonedArticles);
    await encLabels.putAll(clonedLabels);

    // 6. 마이그레이션 완료 플래그 설정
    await _prefsBox.put('hive_encrypted_v1', true);
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
    articlesChangedNotifier.value++;
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
    articlesChangedNotifier.value++;
  }

  // 안 읽음 처리
  static Future<void> markAsUnread(Article article) async {
    article.isRead = false;
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(article, {'isRead': false});
    }
    articlesChangedNotifier.value++;
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
    articlesChangedNotifier.value++;
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
    articlesChangedNotifier.value++;
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
    articlesChangedNotifier.value++;
  }

  // 메모 업데이트
  static Future<void> updateMemo(Article article, String? memo) async {
    article.memo = (memo != null && memo.trim().isEmpty) ? null : memo?.trim();
    article.updatedAt = DateTime.now();
    await article.save();
    if (!skipSync && AuthService.isLoggedIn) {
      await SyncService.syncArticleFields(article, {'memo': article.memo});
    }
    articlesChangedNotifier.value++;
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
    articlesChangedNotifier.value++;
  }

  // 일괄 삭제 — 단일 sync trigger + notifier 1회 발사.
  static Future<void> bulkDelete(List<Article> articles) async {
    if (articles.isEmpty) return;
    if (!skipSync && AuthService.isLoggedIn) {
      for (final a in articles) {
        await SyncService.syncDeleteArticle(a);
      }
    }
    await _box.deleteAll(articles.map((a) => a.key));
    articlesChangedNotifier.value++;
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
    labelsChangedNotifier.value++;
    return label;
  }

  // 라벨 수정
  static Future<void> updateLabel(
    Label label, {
    String? newName,
    Color? newColor,
  }) async {
    final oldName = label.name;
    bool articlesAffected = false;

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
          articlesAffected = true;
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
    labelsChangedNotifier.value++;
    if (articlesAffected) articlesChangedNotifier.value++;
  }

  // 라벨 삭제
  static Future<void> deleteLabel(Label label) async {
    bool articlesAffected = false;
    // 모든 아티클에서 해당 라벨 제거
    for (final article in _box.values) {
      if (article.topicLabels.remove(label.name)) {
        article.updatedAt = DateTime.now();
        await article.save();
        articlesAffected = true;
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
    labelsChangedNotifier.value++;
    if (articlesAffected) articlesChangedNotifier.value++;
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
    articlesChangedNotifier.value++;
  }
}
