// H-2 회귀 테스트: 원격 라벨 삭제 동기화 시 weekly 알림 cancel 누락 수정
//
// 테스트 심(Seam) — Option A (H-1 패턴 동일):
//   NotificationService.cancelOverride 에 추적 함수를 주입한다.
//   기본값 null → 프로덕션은 flutter_local_notifications 플러그인을 직접 사용.
//   @visibleForTesting으로 표시했으므로 테스트 전용.
//
// 핵심 검증 전략:
//   cancelForLabel은 label.delete() 이전에 호출되어야 한다.
//   label.delete() 직후 label.key는 null이 된다(Hive isInBox=false).
//   따라서 cancelOverride 콜백 내에서 label.key가 유효한 int인지 확인하면
//   호출 순서(cancel → delete)를 단일 단언으로 검증할 수 있다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/notification_service.dart';
import 'package:clib/services/sync_service.dart';

/// 테스트용 Label 팩토리
Label _makeLabel({
  required String name,
  required String firestoreId,
  DateTime? deletedAt,
}) {
  final label = Label()
    ..name = name
    ..colorValue = 0xFF5BA67D
    ..createdAt = DateTime(2024, 1, 1)
    ..notificationEnabled = true
    ..notificationDays = [0, 1] // 월, 화
    ..notificationTime = '09:00'
    ..firestoreId = firestoreId
    ..deletedAt = deletedAt;
  return label;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_h2_test_');
    Hive.init(tempDir.path);
    // 어댑터는 프로세스 내 싱글톤이므로 아직 등록되지 않은 경우에만 등록한다
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
    await Hive.openBox('preferences');

    // 테스트마다 심 초기화
    NotificationService.cancelOverride = null;
  });

  tearDown(() async {
    NotificationService.cancelOverride = null;
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('_processLabelsSnapshot — deletedAt 분기 알림 cancel 순서 검증', () {
    test(
      '(H-2) 원격 라벨 deletedAt != null 시 cancelForLabel이 delete 이전에 호출된다',
      () async {
        // ARRANGE: 로컬에 라벨 저장 (notificationEnabled = true)
        final box = Hive.box<Label>('labels');
        final localLabel = _makeLabel(
          name: '테스트라벨',
          firestoreId: 'fs-label-001',
        );
        await box.add(localLabel);
        expect(box.length, 1);

        // 라벨 key는 Hive에 추가된 후에 유효하다
        final savedKey = localLabel.key as int;

        // cancelOverride: cancel 시점에 label.key가 유효한지 기록
        int? cancelledKeyAtCallTime;
        bool? wasInBoxAtCancelTime;
        NotificationService.cancelOverride = (label) async {
          // delete 전이면 key가 유효하고 isInBox = true
          cancelledKeyAtCallTime = label.key as int?;
          wasInBoxAtCancelTime = label.isInBox;
        };

        // 원격 스냅샷: 같은 firestoreId를 가진 라벨이 deletedAt != null
        final remoteDeleted = _makeLabel(
          name: '테스트라벨',
          firestoreId: 'fs-label-001',
          deletedAt: DateTime(2024, 6, 1),
        );

        // ACT: _processLabelsSnapshot 호출 (테스트 전용 래퍼)
        await SyncService.processLabelsSnapshotForTest([remoteDeleted]);

        // ASSERT 1: cancelForLabel이 실제로 호출됐는가
        expect(
          cancelledKeyAtCallTime,
          isNotNull,
          reason: 'cancelForLabel이 호출되지 않았다 — 알림 누수 버그',
        );

        // ASSERT 2: cancel 시점에 label.key가 savedKey와 같았는가
        //           (delete 이후면 key가 null이 되어 이 단언이 실패한다)
        expect(
          cancelledKeyAtCallTime,
          equals(savedKey),
          reason: 'cancelForLabel이 delete 이후에 호출됐다 — key가 이미 무효화됨',
        );

        // ASSERT 3: cancel 시점에 라벨이 아직 box 안에 있었는가
        expect(
          wasInBoxAtCancelTime,
          isTrue,
          reason: 'cancelForLabel 호출 시 라벨이 이미 삭제되어 있었다',
        );

        // ASSERT 4: delete는 실제로 실행됐는가 (정상 삭제 확인)
        expect(
          box.length,
          0,
          reason: '원격 deletedAt 라벨은 로컬에서도 삭제되어야 한다',
        );
      },
    );

    test(
      '(H-2) notificationEnabled=false인 라벨도 cancel은 호출된다',
      () async {
        // ARRANGE: 알림 비활성 라벨
        final box = Hive.box<Label>('labels');
        final localLabel = Label()
          ..name = '알림없는라벨'
          ..colorValue = 0xFF5BA67D
          ..createdAt = DateTime(2024, 1, 1)
          ..notificationEnabled = false
          ..notificationDays = []
          ..notificationTime = '09:00'
          ..firestoreId = 'fs-label-002';
        await box.add(localLabel);

        bool cancelCalled = false;
        NotificationService.cancelOverride = (label) async {
          cancelCalled = true;
        };

        final remoteDeleted = Label()
          ..name = '알림없는라벨'
          ..colorValue = 0xFF5BA67D
          ..createdAt = DateTime(2024, 1, 1)
          ..notificationEnabled = false
          ..notificationDays = []
          ..notificationTime = '09:00'
          ..firestoreId = 'fs-label-002'
          ..deletedAt = DateTime(2024, 6, 1);

        // ACT
        await SyncService.processLabelsSnapshotForTest([remoteDeleted]);

        // ASSERT: cancel은 notificationEnabled 관계없이 호출되어야 한다
        // (cancelForLabel 내부에서 days 루프를 도는 방식이므로 조건 없음)
        expect(cancelCalled, isTrue);
        expect(box.length, 0);
      },
    );

    test(
      '(H-2) deletedAt=null인 원격 라벨은 cancel이 호출되지 않는다',
      () async {
        // ARRANGE: 정상 라벨 (삭제 아님)
        final box = Hive.box<Label>('labels');
        final localLabel = _makeLabel(
          name: '정상라벨',
          firestoreId: 'fs-label-003',
        );
        await box.add(localLabel);

        bool cancelCalled = false;
        NotificationService.cancelOverride = (label) async {
          cancelCalled = true;
        };

        // 원격에서 deletedAt=null → 정상 업데이트 분기
        final remoteAlive = _makeLabel(
          name: '정상라벨',
          firestoreId: 'fs-label-003',
          deletedAt: null,
        )
          ..updatedAt = DateTime(2024, 6, 1);

        // ACT
        await SyncService.processLabelsSnapshotForTest([remoteAlive]);

        // ASSERT: 삭제 분기가 아니므로 cancel 미호출
        expect(cancelCalled, isFalse);
        expect(box.length, 1); // 라벨은 여전히 존재
      },
    );
  });
}
