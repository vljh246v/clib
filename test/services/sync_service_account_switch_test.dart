// H-3 회귀 테스트: 계정 전환 시 Hive 박스 wipe로 데이터 사이펀 영구 차단
//
// 테스트 심(Seam):
//   SyncService.initForTest({String? lastUid, required String newUid}) —
//     계정 전환 감지 + _wipeLocalData 실행 (리스너 없음).
//     lastUid != newUid → articles/labels 박스 wipe + NotificationService.cancelForLabel 호출.
//   NotificationService.cancelOverride —
//     cancelForLabel 플러그인 호출 대신 커스텀 함수를 주입한다 (H-2 기존 심 재사용).
//
// 핵심 검증 전략:
//   1. 계정 전환(lastUid != newUid): articles/labels 박스가 비워진다.
//   2. 같은 계정 재로그인(lastUid == newUid): 박스 데이터가 보존된다.
//   3. 최초 로그인(lastUid == null): 박스 데이터가 보존된다 (게스트 데이터 유지).
//   4. 계정 전환 시 wipe 전에 NotificationService.cancelForLabel이 라벨별로 호출된다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/notification_service.dart';
import 'package:clib/services/sync_service.dart';

/// 테스트용 Article 팩토리
Article _makeArticle({String url = 'https://example.com', String? firestoreId}) {
  return Article()
    ..url = url
    ..title = '테스트 아티클'
    ..thumbnailUrl = null
    ..platform = Platform.etc
    ..topicLabels = []
    ..isRead = false
    ..createdAt = DateTime(2024, 1, 1)
    ..isBookmarked = false
    ..memo = null
    ..firestoreId = firestoreId
    ..updatedAt = null
    ..deletedAt = null;
}

/// 테스트용 Label 팩토리
Label _makeLabel({String name = '테스트라벨', String? firestoreId}) {
  return Label()
    ..name = name
    ..colorValue = 0xFF5BA67D
    ..createdAt = DateTime(2024, 1, 1)
    ..notificationEnabled = false
    ..notificationDays = []
    ..notificationTime = '09:00'
    ..firestoreId = firestoreId
    ..updatedAt = null
    ..deletedAt = null;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_h3_test_');
    Hive.init(tempDir.path);
    // 어댑터는 프로세스 내 싱글톤이므로 중복 등록 방지
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
    await Hive.openBox('preferences');
    // cancelOverride 초기화 (이전 테스트 심 잔류 방지)
    NotificationService.cancelOverride = null;
  });

  tearDown(() async {
    NotificationService.cancelOverride = null;
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('H-3: 계정 전환 시 Hive 박스 wipe로 데이터 사이펀 영구 차단', () {
    // ── Test 1: 계정 전환 → articles/labels 박스가 비워진다 ──
    test(
      '(H-3) 다른 계정 로그인 시 이전 계정의 articles/labels Hive 박스가 비워진다',
      () async {
        // ARRANGE: 이전 계정(userA) uid를 preferences에 저장
        await DatabaseService.saveLastLoginUid('userA');

        // 이전 계정 로컬 데이터 시딩
        final articleBox = Hive.box<Article>('articles');
        await articleBox.add(_makeArticle(url: 'https://example.com/userA-1'));
        await articleBox.add(_makeArticle(url: 'https://example.com/userA-2'));

        final labelBox = Hive.box<Label>('labels');
        await labelBox.add(_makeLabel(name: 'userA-label-1'));
        await labelBox.add(_makeLabel(name: 'userA-label-2'));

        expect(articleBox.length, 2, reason: 'ARRANGE: 아티클 2개 seeded');
        expect(labelBox.length, 2, reason: 'ARRANGE: 라벨 2개 seeded');

        // 알림 취소 심 주입
        NotificationService.cancelOverride = (label) async {};

        // ACT: 다른 계정(userB)으로 전환
        await SyncService.initForTest(
          lastUid: 'userA',
          newUid: 'userB',
        );

        // ASSERT: 두 박스 모두 비워져야 한다
        expect(
          articleBox.isEmpty,
          isTrue,
          reason: '계정 전환 시 articles 박스가 비워져야 한다 (wipe)',
        );
        expect(
          labelBox.isEmpty,
          isTrue,
          reason: '계정 전환 시 labels 박스가 비워져야 한다 (wipe)',
        );

        // ASSERT: lastLoginUid가 newUid로 갱신되어야 한다
        expect(
          DatabaseService.lastLoginUid,
          'userB',
          reason: '계정 전환 후 lastLoginUid가 userB로 갱신되어야 한다',
        );
      },
    );

    // ── Test 2: 같은 계정 재로그인 → 박스 보존 ──
    test(
      '(H-3) 같은 계정 재로그인 시 박스가 보존된다',
      () async {
        // ARRANGE: userB로 이미 로그인되어 있는 상태
        await DatabaseService.saveLastLoginUid('userB');

        final articleBox = Hive.box<Article>('articles');
        await articleBox.add(_makeArticle(url: 'https://example.com/userB-1'));

        final labelBox = Hive.box<Label>('labels');
        await labelBox.add(_makeLabel(name: 'userB-label'));

        // ACT: 같은 계정(userB)으로 재로그인
        await SyncService.initForTest(
          lastUid: 'userB',
          newUid: 'userB',
        );

        // ASSERT: 박스 데이터가 그대로 보존되어야 한다
        expect(
          articleBox.length,
          1,
          reason: '같은 계정 재로그인 시 articles 박스가 보존되어야 한다',
        );
        expect(
          labelBox.length,
          1,
          reason: '같은 계정 재로그인 시 labels 박스가 보존되어야 한다',
        );
      },
    );

    // ── Test 3: 최초 로그인(lastUid=null) → 박스 보존 ──
    test(
      '(H-3) 최초 로그인(lastUid=null) 시 박스가 보존된다',
      () async {
        // ARRANGE: lastLoginUid 없음 (최초 로그인 / 게스트 데이터)
        // (saveLastLoginUid 호출 안 함 → null 상태)
        final articleBox = Hive.box<Article>('articles');
        await articleBox.add(_makeArticle(url: 'https://example.com/guest-1'));

        final labelBox = Hive.box<Label>('labels');
        await labelBox.add(_makeLabel(name: 'guest-label'));

        // ACT: 최초 로그인 (lastUid=null)
        await SyncService.initForTest(
          lastUid: null,
          newUid: 'userNew',
        );

        // ASSERT: 게스트 데이터가 보존되어야 한다 (나중에 Firestore로 업로드됨)
        expect(
          articleBox.length,
          1,
          reason: '최초 로그인 시 게스트 아티클이 보존되어야 한다',
        );
        expect(
          labelBox.length,
          1,
          reason: '최초 로그인 시 게스트 라벨이 보존되어야 한다',
        );
      },
    );

    // ── Test 4: 계정 전환 시 NotificationService.cancelForLabel이 라벨별로 호출된다 ──
    test(
      '(H-3) 계정 전환 시 wipe 전에 NotificationService.cancelForLabel이 호출된다',
      () async {
        // ARRANGE
        await DatabaseService.saveLastLoginUid('userA');

        final labelBox = Hive.box<Label>('labels');
        await labelBox.add(_makeLabel(name: 'label-alpha'));
        await labelBox.add(_makeLabel(name: 'label-beta'));

        final cancelledNames = <String>[];
        // cancelOverride 심 주입: 취소된 라벨 이름 수집
        NotificationService.cancelOverride = (label) async {
          cancelledNames.add(label.name);
        };

        // ACT: 계정 전환
        await SyncService.initForTest(
          lastUid: 'userA',
          newUid: 'userB',
        );

        // ASSERT: 두 라벨 모두에 대해 cancelForLabel이 호출되어야 한다
        expect(
          cancelledNames,
          containsAll(['label-alpha', 'label-beta']),
          reason: 'wipe 전 모든 라벨에 대해 cancelForLabel이 호출되어야 한다',
        );
        expect(
          cancelledNames.length,
          2,
          reason: 'seeded 라벨 2개에 대해 정확히 2번 호출되어야 한다',
        );

        // ASSERT: wipe 후 박스는 비어있어야 한다
        expect(
          labelBox.isEmpty,
          isTrue,
          reason: '알림 취소 후 labels 박스가 비워져야 한다',
        );
      },
    );
  });
}
