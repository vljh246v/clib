// H-1 회귀 테스트: Firestore softDelete 실패 시 로컬 Hive 아티클 보존
//
// 테스트 심(Seam) — Option A:
//   DatabaseService.syncDeleteOverride 에 실패하는 함수를 주입한다.
//   기본값 null → 프로덕션은 AuthService.isLoggedIn 게이트를 통해
//   SyncService.syncDeleteArticle 를 호출하므로 기존 동작 불변.
//   @visibleForTesting으로 표시했으므로 테스트 전용.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

Article _makeArticle({String? firestoreId}) {
  return Article()
    ..url = 'https://example.com/test'
    ..title = '테스트 아티클'
    ..thumbnailUrl = null
    ..platform = Platform.etc
    ..topicLabels = []
    ..isRead = false
    ..isBookmarked = false
    ..createdAt = DateTime(2024, 1, 1)
    ..firestoreId = firestoreId;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    // 어댑터는 프로세스 내 싱글톤이므로 아직 등록되지 않은 경우에만 등록한다
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
    await Hive.openBox('preferences');

    // 테스트마다 DatabaseService 상태 초기화
    DatabaseService.skipSync = false;
    DatabaseService.syncDeleteOverride = null;
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
    DatabaseService.syncDeleteOverride = null;
  });

  // ── RED: 이 테스트는 픽스 전에는 실패해야 한다 ──

  group('deleteArticle — Firestore 실패 시 로컬 보존', () {
    test(
      '(H-1) syncDelete가 예외를 던질 때 로컬 Hive 아티클이 삭제되지 않아야 한다',
      () async {
        // ARRANGE: 아티클을 Hive에 저장
        final article = _makeArticle(firestoreId: 'fs-001');
        await Hive.box<Article>('articles').add(article);
        expect(Hive.box<Article>('articles').length, 1);

        // syncDelete가 실패하는 오버라이드 주입
        DatabaseService.syncDeleteOverride = (_) async {
          throw Exception('Firestore 오프라인');
        };

        // ACT + ASSERT: 예외가 전파되어야 함
        await expectLater(
          () => DatabaseService.deleteArticle(article),
          throwsException,
        );

        // ASSERT: 로컬 Hive 아티클이 여전히 존재해야 함
        expect(
          Hive.box<Article>('articles').length,
          1,
          reason: 'Firestore 동기화 실패 시 로컬 아티클이 보존되어야 한다',
        );
      },
    );

    test(
      '(H-1) syncDelete 오버라이드가 null이고 skipSync=true이면 정상 삭제된다',
      () async {
        // ARRANGE
        DatabaseService.skipSync = true;
        final article = _makeArticle();
        await Hive.box<Article>('articles').add(article);
        expect(Hive.box<Article>('articles').length, 1);

        // ACT
        await DatabaseService.deleteArticle(article);

        // ASSERT: skipSync=true이면 동기화 없이 로컬 삭제 성공
        expect(Hive.box<Article>('articles').length, 0);
      },
    );

    test(
      '(H-1) syncDelete 오버라이드가 성공하면 로컬 아티클이 삭제된다',
      () async {
        // ARRANGE
        final article = _makeArticle(firestoreId: 'fs-002');
        await Hive.box<Article>('articles').add(article);
        expect(Hive.box<Article>('articles').length, 1);

        // 성공하는 오버라이드 주입
        DatabaseService.syncDeleteOverride = (_) async {};

        // ACT
        await DatabaseService.deleteArticle(article);

        // ASSERT: 동기화 성공 → 로컬도 삭제됨
        expect(Hive.box<Article>('articles').length, 0);
      },
    );

    test(
      '(H-1) 여러 아티클 일괄 삭제(UI 루프) 중 하나가 실패하면 해당 아티클은 보존된다',
      () async {
        // ARRANGE: 2개 아티클 저장
        final article1 = _makeArticle(firestoreId: 'fs-bulk-1')
          ..url = 'https://example.com/1'
          ..title = '아티클 1';
        final article2 = _makeArticle(firestoreId: 'fs-bulk-2')
          ..url = 'https://example.com/2'
          ..title = '아티클 2';
        final box = Hive.box<Article>('articles');
        await box.add(article1);
        await box.add(article2);
        expect(box.length, 2);

        // article1만 Firestore 실패, article2는 성공
        DatabaseService.syncDeleteOverride = (a) async {
          if (a.firestoreId == 'fs-bulk-1') {
            throw Exception('article1 Firestore 실패');
          }
        };

        // ACT: UI 루프 패턴 (실패는 무시하고 계속하는 경우 vs 중단하는 경우)
        // 현재 픽스는 rethrow — 호출자가 에러를 받도록 한다
        // 일괄 루프에서 첫 실패 후 나머지는 처리되지 않을 수 있다
        Exception? caughtError;
        try {
          for (final a in [article1, article2]) {
            await DatabaseService.deleteArticle(a);
          }
        } on Exception catch (e) {
          caughtError = e;
        }

        // ASSERT: 예외가 전파됨
        expect(caughtError, isNotNull);

        // article1은 보존됨 (Firestore 실패)
        expect(
          box.length,
          greaterThan(0),
          reason: 'Firestore 실패한 아티클은 보존되어야 한다',
        );
      },
    );
  });
}
