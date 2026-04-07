import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/firestore_service.dart';
import 'package:clib/main.dart';

class SyncService {
  static StreamSubscription? _articleSub;
  static StreamSubscription? _labelSub;
  static bool _articleSyncing = false;
  static bool _labelSyncing = false;

  /// 첫 스냅샷에서 로컬→리모트 머지 수행 여부
  static bool _articleMergeDone = false;
  static bool _labelMergeDone = false;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// 로그인 시 호출 — snapshot listener 시작
  static Future<void> init(User user) async {
    dispose();

    // 계정이 바뀌면 기존 firestoreId 초기화
    final lastUid = DatabaseService.lastLoginUid;
    if (lastUid != null && lastUid != user.uid) {
      debugPrint('계정 전환 감지 ($lastUid → ${user.uid}): firestoreId 초기화');
      await _clearFirestoreIds();
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
  }

  /// 계정 전환 시 이전 계정의 firestoreId 제거
  static Future<void> _clearFirestoreIds() async {
    final articleBox = Hive.box<Article>('articles');
    for (final article in articleBox.values) {
      if (article.firestoreId != null) {
        article.firestoreId = null;
        article.updatedAt = null;
        await article.save();
      }
    }
    final labelBox = Hive.box<Label>('labels');
    for (final label in labelBox.values) {
      if (label.firestoreId != null) {
        label.firestoreId = null;
        label.updatedAt = null;
        await label.save();
      }
    }
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
    if (_articleSyncing) return;
    _articleSyncing = true;

    try {
      final box = Hive.box<Article>('articles');

      // 원격 firestoreId → Article 맵
      final remoteMap = <String, Article>{};
      for (final article in remoteArticles) {
        if (article.firestoreId != null) {
          remoteMap[article.firestoreId!] = article;
        }
      }

      // 기존 로컬 firestoreId → Article 맵
      final localByFsId = <String, Article>{};
      // URL → Article 맵 (중복 방지용)
      final localByUrl = <String, Article>{};
      for (final article in box.values) {
        if (article.firestoreId != null) {
          localByFsId[article.firestoreId!] = article;
        }
        localByUrl[article.url] = article;
      }

      // 원격에서 온 데이터 반영
      for (final entry in remoteMap.entries) {
        final remote = entry.value;

        if (remote.deletedAt != null) {
          final local = localByFsId[entry.key];
          if (local != null && local.isInBox) {
            await local.delete();
          }
          continue;
        }

        final local = localByFsId[entry.key];
        if (local != null) {
          // firestoreId로 매칭 → 업데이트
          if (remote.updatedAt != null &&
              (local.updatedAt == null ||
                  remote.updatedAt!.isAfter(local.updatedAt!))) {
            local
              ..url = remote.url
              ..title = remote.title
              ..thumbnailUrl = remote.thumbnailUrl
              ..platform = remote.platform
              ..topicLabels = remote.topicLabels
              ..isRead = remote.isRead
              ..isBookmarked = remote.isBookmarked
              ..memo = remote.memo
              ..updatedAt = remote.updatedAt;
            await local.save();
          }
        } else {
          // firestoreId 매칭 실패 → URL로 중복 체크
          final byUrl = localByUrl[remote.url];
          if (byUrl != null) {
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
          } else {
            // 완전히 새로운 아티클 → Hive에 추가
            await box.add(remote);
          }
        }
      }

      // 첫 스냅샷: 리모트에 없는 로컬 아티클을 업로드
      if (!_articleMergeDone) {
        _articleMergeDone = true;
        final uid = _uid;
        if (uid != null) {
          // 리모트 URL → firestoreId 맵 (업로드 시 재사용 판단용)
          final remoteUrlToId = <String, String>{};
          for (final entry in remoteMap.entries) {
            if (entry.value.deletedAt == null) {
              remoteUrlToId[entry.value.url] = entry.key;
            }
          }
          await _uploadUnlinkedArticles(uid, remoteUrlToId);
        }
      }

      // 홈화면 갱신 알림
      articlesChangedNotifier.value++;
    } finally {
      _articleSyncing = false;
    }
  }

  /// Firestore 라벨 스냅샷 → Hive 반영
  static Future<void> _onLabelsSnapshot(List<Label> remoteLabels) async {
    if (_labelSyncing) return;
    _labelSyncing = true;

    try {
      final box = Hive.box<Label>('labels');

      final remoteMap = <String, Label>{};
      for (final label in remoteLabels) {
        if (label.firestoreId != null) {
          remoteMap[label.firestoreId!] = label;
        }
      }

      final localByFsId = <String, Label>{};
      final localByName = <String, Label>{};
      for (final label in box.values) {
        if (label.firestoreId != null) {
          localByFsId[label.firestoreId!] = label;
        }
        localByName[label.name] = label;
      }

      for (final entry in remoteMap.entries) {
        final remote = entry.value;

        if (remote.deletedAt != null) {
          final local = localByFsId[entry.key];
          if (local != null && local.isInBox) {
            await local.delete();
          }
          continue;
        }

        final local = localByFsId[entry.key];
        if (local != null) {
          if (remote.updatedAt != null &&
              (local.updatedAt == null ||
                  remote.updatedAt!.isAfter(local.updatedAt!))) {
            local
              ..name = remote.name
              ..colorValue = remote.colorValue
              ..updatedAt = remote.updatedAt;
            await local.save();
          }
        } else {
          final byName = localByName[remote.name];
          if (byName != null) {
            byName
              ..firestoreId = remote.firestoreId
              ..colorValue = remote.colorValue
              ..updatedAt = remote.updatedAt;
            await byName.save();
          } else {
            await box.add(remote);
          }
        }
      }

      // 첫 스냅샷: 리모트에 없는 로컬 라벨을 업로드
      if (!_labelMergeDone) {
        _labelMergeDone = true;
        final uid = _uid;
        if (uid != null) {
          final remoteNameToId = <String, String>{};
          for (final entry in remoteMap.entries) {
            if (entry.value.deletedAt == null) {
              remoteNameToId[entry.value.name] = entry.key;
            }
          }
          await _uploadUnlinkedLabels(uid, remoteNameToId);
        }
      }
    } finally {
      _labelSyncing = false;
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
  static Future<void> syncDeleteArticle(Article article) async {
    final uid = _uid;
    if (uid == null || article.firestoreId == null) return;

    try {
      await FirestoreService.softDeleteArticle(uid, article.firestoreId!);
    } catch (e) {
      debugPrint('아티클 삭제 동기화 실패: $e');
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
}
