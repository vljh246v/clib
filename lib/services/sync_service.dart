import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/firestore_service.dart';
import 'package:clib/services/notification_service.dart';
import 'package:clib/state/app_notifiers.dart';

class SyncService {
  static StreamSubscription? _articleSub;
  static StreamSubscription? _labelSub;
  static bool _articleSyncing = false;
  static bool _labelSyncing = false;

  /// 처리 중 새 스냅샷이 도착하면 여기에 저장 → 현재 처리 완료 후 재처리
  static List<Article>? _pendingArticleSnapshot;
  static List<Label>? _pendingLabelSnapshot;

  /// 첫 스냅샷에서 로컬→리모트 머지 수행 여부
  static bool _articleMergeDone = false;
  static bool _labelMergeDone = false;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// 로그인 시 호출 — snapshot listener 시작
  static Future<void> init(User user) async {
    dispose();

    // 계정이 바뀌면 이전 계정의 로컬 데이터를 완전히 wipe — (H-3)
    // in-memory 플래그로는 앱 재시작 후 동일 계정 재로그인 시 우회가 가능하므로
    // 영구 차단을 위해 Hive 박스를 비운다. 이전 계정 데이터는 해당 계정의
    // Firestore에 보존되므로 재로그인 시 복구 가능하다.
    final lastUid = DatabaseService.lastLoginUid;
    if (lastUid != null && lastUid != user.uid) {
      debugPrint('계정 전환 감지 ($lastUid → ${user.uid}): 로컬 데이터 wipe');
      await _wipeLocalData();
    }
    await DatabaseService.saveLastLoginUid(user.uid);

    // 첫 스냅샷에서 머지 수행하도록 플래그 초기화
    _articleMergeDone = false;
    _labelMergeDone = false;

    // Firestore → Hive 실시간 동기화 (첫 스냅샷이 머지 역할을 겸함)
    _articleSub = FirestoreService.listenArticles(user.uid).listen(
      _onArticlesSnapshot,
      onError: (e) => debugPrint('아티클 동기화 오류: $e'),
    );

    _labelSub = FirestoreService.listenLabels(user.uid).listen(
      _onLabelsSnapshot,
      onError: (e) => debugPrint('라벨 동기화 오류: $e'),
    );
  }

  /// 로그아웃 시 호출 — listener 해제
  static void dispose() {
    _articleSub?.cancel();
    _articleSub = null;
    _labelSub?.cancel();
    _labelSub = null;
    _pendingArticleSnapshot = null;
    _pendingLabelSnapshot = null;
  }

  /// 계정 전환 시 로컬 articles/labels 박스를 완전히 비운다.
  /// 라벨 알림은 박스 clear 이전에 취소한다 (clear 후에는 label.key가 무효화됨). — (H-3)
  static Future<void> _wipeLocalData() async {
    final labelBox = Hive.box<Label>('labels');
    // clear() 전에 라이브 뷰에서 분리된 리스트를 만들어 알림 취소
    final labelsToCancel = labelBox.values.toList();
    for (final label in labelsToCancel) {
      await NotificationService.cancelForLabel(label);
    }
    await labelBox.clear();
    await Hive.box<Article>('articles').clear();
    // 구독 중인 Cubit/Bloc이 빈 상태로 재로드하도록 알림 발사
    articlesChangedNotifier.value++;
    labelsChangedNotifier.value++;
  }

  /// 첫 스냅샷 이후 firestoreId 없는 로컬 아티클을 업로드
  static Future<void> _uploadUnlinkedArticles(
    String uid,
    Map<String, String> remoteUrlToId,
  ) async {
    final box = Hive.box<Article>('articles');
    final toUpload = <Article>[];

    for (final article in box.values) {
      if (article.firestoreId != null) continue;

      // 리모트에 같은 URL이 있으면 firestoreId 연결
      final existingId = remoteUrlToId[article.url];
      if (existingId != null) {
        article.firestoreId = existingId;
        if (article.isInBox) await article.save();
      } else {
        toUpload.add(article);
      }
    }

    if (toUpload.isNotEmpty) {
      debugPrint('초기 동기화: 아티클 ${toUpload.length}개 업로드');
      await FirestoreService.batchUpload(uid, toUpload, []);
    }
  }

  /// 첫 스냅샷 이후 firestoreId 없는 로컬 라벨을 업로드
  static Future<void> _uploadUnlinkedLabels(
    String uid,
    Map<String, String> remoteNameToId,
  ) async {
    final box = Hive.box<Label>('labels');
    final toUpload = <Label>[];

    for (final label in box.values) {
      if (label.firestoreId != null) continue;

      final existingId = remoteNameToId[label.name];
      if (existingId != null) {
        label.firestoreId = existingId;
        if (label.isInBox) await label.save();
      } else {
        toUpload.add(label);
      }
    }

    if (toUpload.isNotEmpty) {
      debugPrint('초기 동기화: 라벨 ${toUpload.length}개 업로드');
      await FirestoreService.batchUpload(uid, [], toUpload);
    }
  }

  /// Firestore 아티클 스냅샷 → Hive 반영
  static Future<void> _onArticlesSnapshot(List<Article> remoteArticles) async {
    if (_articleSyncing) {
      // 처리 중이면 최신 스냅샷을 보관 → 현재 처리 완료 후 재처리
      _pendingArticleSnapshot = remoteArticles;
      return;
    }
    _articleSyncing = true;

    try {
      await _processArticlesSnapshot(remoteArticles);

      // 처리 중 도착한 스냅샷이 있으면 재처리
      while (_pendingArticleSnapshot != null) {
        final pending = _pendingArticleSnapshot!;
        _pendingArticleSnapshot = null;
        await _processArticlesSnapshot(pending);
      }
    } finally {
      _articleSyncing = false;
    }
  }

  static Future<void> _processArticlesSnapshot(
      List<Article> remoteArticles) async {
    final box = Hive.box<Article>('articles');
    bool changed = false;

    // 원격 firestoreId → Article 맵
    final remoteMap = <String, Article>{};
    for (final article in remoteArticles) {
      if (article.firestoreId != null) {
        remoteMap[article.firestoreId!] = article;
      }
    }

    // 로컬 맵 빌드 (변경 시 함께 업데이트하여 동시 수정 대응)
    final localByFsId = <String, Article>{};
    final localByUrl = <String, Article>{};
    for (final a in box.values) {
      if (a.firestoreId != null) localByFsId[a.firestoreId!] = a;
      localByUrl[a.url] = a;
    }

    // 원격에서 온 데이터 반영
    for (final entry in remoteMap.entries) {
      final remote = entry.value;

      if (remote.deletedAt != null) {
        final local = localByFsId[entry.key];
        if (local != null && local.isInBox) {
          localByFsId.remove(entry.key);
          localByUrl.remove(local.url);
          await local.delete();
          changed = true;
        }
        continue;
      }

      final byFsId = localByFsId[entry.key];
      // firestoreId 매칭 실패 시 현재 box에서 URL 재확인 (동시 추가 대응)
      final byUrl = localByFsId.containsKey(entry.key)
          ? null
          : localByUrl[remote.url] ?? box.values.cast<Article?>().firstWhere(
              (a) => a!.url == remote.url, orElse: () => null);

      if (byFsId != null) {
        // firestoreId로 매칭 → 업데이트
        if (remote.updatedAt != null &&
            (byFsId.updatedAt == null ||
                remote.updatedAt!.isAfter(byFsId.updatedAt!))) {
          // 사용자에게 보이는 데이터가 실제로 변경된 경우에만 UI 갱신
          final dataChanged = byFsId.url != remote.url ||
              byFsId.title != remote.title ||
              byFsId.isRead != remote.isRead ||
              byFsId.isBookmarked != remote.isBookmarked ||
              byFsId.memo != remote.memo ||
              byFsId.topicLabels.join(',') != remote.topicLabels.join(',');
          byFsId
            ..url = remote.url
            ..title = remote.title
            ..thumbnailUrl = remote.thumbnailUrl
            ..platform = remote.platform
            ..topicLabels = remote.topicLabels
            ..isRead = remote.isRead
            ..isBookmarked = remote.isBookmarked
            ..memo = remote.memo
            ..updatedAt = remote.updatedAt;
          await byFsId.save();
          if (dataChanged) changed = true;
        }
      } else if (byUrl != null) {
        // URL로 매칭 → firestoreId 연결 + 업데이트
        byUrl
          ..firestoreId = remote.firestoreId
          ..title = remote.title
          ..thumbnailUrl = remote.thumbnailUrl
          ..platform = remote.platform
          ..topicLabels = remote.topicLabels
          ..isRead = remote.isRead
          ..isBookmarked = remote.isBookmarked
          ..memo = remote.memo
          ..updatedAt = remote.updatedAt;
        await byUrl.save();
        localByFsId[remote.firestoreId!] = byUrl;
        changed = true;
      } else {
        // 완전히 새로운 아티클 → Hive에 추가
        await box.add(remote);
        if (remote.firestoreId != null) localByFsId[remote.firestoreId!] = remote;
        localByUrl[remote.url] = remote;
        changed = true;
      }
    }

    // 첫 스냅샷: 리모트에 없는 로컬 아티클을 업로드
    // wipe 후에는 박스가 비어있으므로 업로드할 항목이 없어 자연스럽게 no-op — (H-3)
    if (!_articleMergeDone) {
      final uid = _uid;
      if (uid != null) {
        try {
          final remoteUrlToId = <String, String>{};
          for (final entry in remoteMap.entries) {
            if (entry.value.deletedAt == null) {
              remoteUrlToId[entry.value.url] = entry.key;
            }
          }
          await _uploadUnlinkedArticles(uid, remoteUrlToId);
          _articleMergeDone = true;
        } catch (e) {
          debugPrint('아티클 초기 머지 실패 (다음 스냅샷에서 재시도): $e');
        }
      } else {
        _articleMergeDone = true;
      }
    }

    // 실제 변경이 있을 때만 홈화면 갱신
    if (changed) {
      articlesChangedNotifier.value++;
    }
  }

  /// Firestore 라벨 스냅샷 → Hive 반영
  static Future<void> _onLabelsSnapshot(List<Label> remoteLabels) async {
    if (_labelSyncing) {
      _pendingLabelSnapshot = remoteLabels;
      return;
    }
    _labelSyncing = true;

    try {
      await _processLabelsSnapshot(remoteLabels);

      while (_pendingLabelSnapshot != null) {
        final pending = _pendingLabelSnapshot!;
        _pendingLabelSnapshot = null;
        await _processLabelsSnapshot(pending);
      }
    } finally {
      _labelSyncing = false;
    }
  }

  static Future<void> _processLabelsSnapshot(List<Label> remoteLabels) async {
    final box = Hive.box<Label>('labels');
    bool changed = false;

    final remoteMap = <String, Label>{};
    for (final label in remoteLabels) {
      if (label.firestoreId != null) {
        remoteMap[label.firestoreId!] = label;
      }
    }

    // 로컬 맵 빌드 (변경 시 함께 업데이트)
    final localByFsId = <String, Label>{};
    final localByName = <String, Label>{};
    for (final l in box.values) {
      if (l.firestoreId != null) localByFsId[l.firestoreId!] = l;
      localByName[l.name] = l;
    }

    for (final entry in remoteMap.entries) {
      final remote = entry.value;

      if (remote.deletedAt != null) {
        final local = localByFsId[entry.key];
        if (local != null && local.isInBox) {
          localByFsId.remove(entry.key);
          localByName.remove(local.name);
          // 알림 취소를 delete 이전에 수행 — delete 후에는 label.key가 무효화됨 (H-2)
          await NotificationService.cancelForLabel(local);
          await local.delete();
          changed = true;
        }
        continue;
      }

      final byFsId = localByFsId[entry.key];
      final byName = localByFsId.containsKey(entry.key)
          ? null
          : localByName[remote.name] ?? box.values.cast<Label?>().firstWhere(
              (l) => l!.name == remote.name, orElse: () => null);

      if (byFsId != null) {
        if (remote.updatedAt != null &&
            (byFsId.updatedAt == null ||
                remote.updatedAt!.isAfter(byFsId.updatedAt!))) {
          final dataChanged = byFsId.name != remote.name ||
              byFsId.colorValue != remote.colorValue;
          byFsId
            ..name = remote.name
            ..colorValue = remote.colorValue
            ..updatedAt = remote.updatedAt;
          await byFsId.save();
          if (dataChanged) changed = true;
        }
      } else if (byName != null) {
        byName
          ..firestoreId = remote.firestoreId
          ..colorValue = remote.colorValue
          ..updatedAt = remote.updatedAt;
        await byName.save();
        localByFsId[remote.firestoreId!] = byName;
        changed = true;
      } else {
        await box.add(remote);
        if (remote.firestoreId != null) localByFsId[remote.firestoreId!] = remote;
        localByName[remote.name] = remote;
        changed = true;
      }
    }

    // 첫 스냅샷: 리모트에 없는 로컬 라벨을 업로드
    // wipe 후에는 박스가 비어있으므로 업로드할 항목이 없어 자연스럽게 no-op — (H-3)
    if (!_labelMergeDone) {
      final uid = _uid;
      if (uid != null) {
        try {
          final remoteNameToId = <String, String>{};
          for (final entry in remoteMap.entries) {
            if (entry.value.deletedAt == null) {
              remoteNameToId[entry.value.name] = entry.key;
            }
          }
          await _uploadUnlinkedLabels(uid, remoteNameToId);
          _labelMergeDone = true;
        } catch (e) {
          debugPrint('라벨 초기 머지 실패 (다음 스냅샷에서 재시도): $e');
        }
      } else {
        _labelMergeDone = true;
      }
    }

    // 실제 변경이 있을 때만 라이브러리 갱신
    if (changed) {
      labelsChangedNotifier.value++;
    }
  }

  // ── DatabaseService에서 호출하는 동기화 메서드 ──

  /// 아티클 저장 후 Firestore에 업로드
  static Future<void> syncArticle(Article article) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final firestoreId = await FirestoreService.uploadArticle(uid, article);
      if (article.firestoreId == null) {
        article.firestoreId = firestoreId;
        if (article.isInBox) await article.save();
      }
    } catch (e) {
      debugPrint('아티클 동기화 실패: $e');
    }
  }

  /// 여러 아티클의 필드를 일괄 동기화 (batch write → 스냅샷 1회)
  static Future<void> syncBulkArticleFields(
    List<Article> articles,
    Map<String, dynamic> fields,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    final syncable = articles.where((a) => a.firestoreId != null).toList();
    if (syncable.isEmpty) return;

    try {
      await FirestoreService.batchUpdateArticleFields(uid, syncable, fields);
    } catch (e) {
      debugPrint('일괄 아티클 동기화 실패: $e');
    }
  }

  /// 아티클 필드 업데이트 동기화
  static Future<void> syncArticleFields(
    Article article,
    Map<String, dynamic> fields,
  ) async {
    final uid = _uid;
    if (uid == null || article.firestoreId == null) return;

    try {
      await FirestoreService.updateArticleFields(
          uid, article.firestoreId!, fields);
    } catch (e) {
      debugPrint('아티클 필드 동기화 실패: $e');
    }
  }

  /// 아티클 삭제 동기화
  /// Firestore softDelete 실패 시 예외를 rethrow하여 호출자(DatabaseService.deleteArticle)가
  /// 로컬 Hive 삭제를 차단할 수 있도록 한다 (H-1 부활 버그 수정).
  static Future<void> syncDeleteArticle(Article article) async {
    final uid = _uid;
    if (uid == null || article.firestoreId == null) return;

    try {
      await FirestoreService.softDeleteArticle(uid, article.firestoreId!);
    } catch (e) {
      debugPrint('아티클 삭제 동기화 실패: $e');
      rethrow; // 로컬 삭제 차단을 위해 예외를 상위로 전파한다
    }
  }

  /// 라벨 저장 후 Firestore에 업로드
  static Future<void> syncLabel(Label label) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final firestoreId = await FirestoreService.uploadLabel(uid, label);
      if (label.firestoreId == null) {
        label.firestoreId = firestoreId;
        if (label.isInBox) await label.save();
      }
    } catch (e) {
      debugPrint('라벨 동기화 실패: $e');
    }
  }

  /// 라벨 필드 업데이트 동기화
  static Future<void> syncLabelFields(
    Label label,
    Map<String, dynamic> fields,
  ) async {
    final uid = _uid;
    if (uid == null || label.firestoreId == null) return;

    try {
      await FirestoreService.updateLabelFields(
          uid, label.firestoreId!, fields);
    } catch (e) {
      debugPrint('라벨 필드 동기화 실패: $e');
    }
  }

  /// 라벨 삭제 동기화
  static Future<void> syncDeleteLabel(Label label) async {
    final uid = _uid;
    if (uid == null || label.firestoreId == null) return;

    try {
      await FirestoreService.softDeleteLabel(uid, label.firestoreId!);
    } catch (e) {
      debugPrint('라벨 삭제 동기화 실패: $e');
    }
  }

  // ── 테스트 전용 헬퍼 ──

  /// 테스트에서 _processLabelsSnapshot을 직접 호출할 수 있도록 노출한다.
  /// _labelMergeDone을 true로 설정해 FirebaseAuth 접근(uid 조회)을 우회한다.
  @visibleForTesting
  static Future<void> processLabelsSnapshotForTest(
      List<Label> remoteLabels) async {
    _labelMergeDone = true; // uid 조회(FirebaseAuth) 경로 건너뜀
    await _processLabelsSnapshot(remoteLabels);
  }

  // ── H-3 테스트 전용 헬퍼 ──

  /// 계정 전환 감지 + wipe 실행을 검증하는 단위 테스트용 진입점.
  /// FirebaseAuth / Firestore 리스너를 생략하므로 단위 테스트에서 안전하게 호출 가능.
  /// lastUid != newUid 시 _wipeLocalData()를 실행하고 lastLoginUid를 newUid로 갱신한다.
  @visibleForTesting
  static Future<void> initForTest({
    required String? lastUid,
    required String newUid,
  }) async {
    if (lastUid != null && lastUid != newUid) {
      await _wipeLocalData();
    }
    await DatabaseService.saveLastLoginUid(newUid);

    _articleMergeDone = false;
    _labelMergeDone = false;
  }
}
