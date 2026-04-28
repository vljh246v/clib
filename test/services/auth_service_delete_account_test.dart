// M-2 회귀 테스트: deleteAccount 부분 실패 시 SyncService 복원 + 에러 전파
//
// 테스트 전략:
//   AuthService.performDeleteAccount()는 각 단계를 콜백으로 주입받아 오케스트레이션한다.
//   실제 FirebaseAuth / Firestore / Hive 의존 없이 순수 호출 순서와 복원 로직을 검증한다.
//
// 검증 케이스:
//   1. 정상 경로: 모든 단계 성공 → 순서대로 호출, syncReinit 미호출
//   2. deleteRemote 실패: syncDispose·deleteRemote 호출 후 syncReinit 호출, authDelete·localCleanup 미호출, 원래 예외 rethrow
//   3. authDelete 실패: syncDispose·deleteRemote·authDelete 호출 후 syncReinit 호출, localCleanup 미호출, 원래 예외 rethrow
//   4. localCleanup 실패: 모든 이전 단계 호출 후 rethrow, syncReinit 미호출

import 'package:flutter_test/flutter_test.dart';
import 'package:clib/services/auth_service.dart';

void main() {
  group('M-2: performDeleteAccount 오케스트레이션', () {
    // ── Test 1: 정상 경로 ──
    test(
      '(M-2) 모든 단계 성공 시 syncDispose·deleteRemote·authDelete·localCleanup이 순서대로 호출되고 syncReinit은 호출되지 않는다',
      () async {
        final calls = <String>[];

        await AuthService.performDeleteAccount(
          uid: 'test-uid',
          syncDispose: () async => calls.add('syncDispose'),
          deleteRemote: (uid) async => calls.add('deleteRemote:$uid'),
          authDelete: () async => calls.add('authDelete'),
          syncReinit: () async => calls.add('syncReinit'),
          localCleanup: () async => calls.add('localCleanup'),
        );

        expect(
          calls,
          equals(['syncDispose', 'deleteRemote:test-uid', 'authDelete', 'localCleanup']),
          reason: '정상 경로: syncDispose → deleteRemote → authDelete → localCleanup 순서',
        );
        expect(
          calls.contains('syncReinit'),
          isFalse,
          reason: '정상 경로에서 syncReinit은 호출되지 않아야 한다',
        );
      },
    );

    // ── Test 2: deleteRemote 실패 ──
    test(
      '(M-2) deleteRemote 실패 시 syncDispose·deleteRemote 호출 후 syncReinit 호출, authDelete·localCleanup 미호출, 원래 예외 rethrow',
      () async {
        final calls = <String>[];
        final originalException = Exception('Firestore 삭제 실패');

        expect(
          () => AuthService.performDeleteAccount(
            uid: 'test-uid',
            syncDispose: () async => calls.add('syncDispose'),
            deleteRemote: (uid) async {
              calls.add('deleteRemote:$uid');
              throw originalException;
            },
            authDelete: () async => calls.add('authDelete'),
            syncReinit: () async => calls.add('syncReinit'),
            localCleanup: () async => calls.add('localCleanup'),
          ),
          throwsA(same(originalException)),
          reason: '원래 예외가 그대로 전파되어야 한다',
        );

        // Future가 완료될 때까지 대기
        await Future<void>.delayed(Duration.zero);

        expect(
          calls,
          equals(['syncDispose', 'deleteRemote:test-uid', 'syncReinit']),
          reason: 'deleteRemote 실패: syncDispose → deleteRemote → syncReinit 순서',
        );
        expect(
          calls.contains('authDelete'),
          isFalse,
          reason: 'deleteRemote 실패 시 authDelete는 호출되지 않아야 한다',
        );
        expect(
          calls.contains('localCleanup'),
          isFalse,
          reason: 'deleteRemote 실패 시 localCleanup은 호출되지 않아야 한다',
        );
      },
    );

    // ── Test 3: authDelete 실패 ──
    test(
      '(M-2) authDelete 실패 시 syncDispose·deleteRemote·authDelete 호출 후 syncReinit 호출, localCleanup 미호출, 원래 예외 rethrow',
      () async {
        final calls = <String>[];
        final originalException = Exception('requires-recent-login');

        expect(
          () => AuthService.performDeleteAccount(
            uid: 'test-uid',
            syncDispose: () async => calls.add('syncDispose'),
            deleteRemote: (uid) async => calls.add('deleteRemote:$uid'),
            authDelete: () async {
              calls.add('authDelete');
              throw originalException;
            },
            syncReinit: () async => calls.add('syncReinit'),
            localCleanup: () async => calls.add('localCleanup'),
          ),
          throwsA(same(originalException)),
          reason: '원래 예외가 그대로 전파되어야 한다',
        );

        await Future<void>.delayed(Duration.zero);

        expect(
          calls,
          equals(['syncDispose', 'deleteRemote:test-uid', 'authDelete', 'syncReinit']),
          reason: 'authDelete 실패: syncDispose → deleteRemote → authDelete → syncReinit 순서',
        );
        expect(
          calls.contains('localCleanup'),
          isFalse,
          reason: 'authDelete 실패 시 localCleanup은 호출되지 않아야 한다',
        );
      },
    );

    // ── Test 4: localCleanup 실패 ──
    test(
      '(M-2) localCleanup 실패 시 모든 이전 단계 호출 후 rethrow, syncReinit은 호출되지 않는다',
      () async {
        final calls = <String>[];
        final originalException = Exception('Hive flush 실패');

        expect(
          () => AuthService.performDeleteAccount(
            uid: 'test-uid',
            syncDispose: () async => calls.add('syncDispose'),
            deleteRemote: (uid) async => calls.add('deleteRemote:$uid'),
            authDelete: () async => calls.add('authDelete'),
            syncReinit: () async => calls.add('syncReinit'),
            localCleanup: () async {
              calls.add('localCleanup');
              throw originalException;
            },
          ),
          throwsA(same(originalException)),
          reason: '원래 예외가 그대로 전파되어야 한다',
        );

        await Future<void>.delayed(Duration.zero);

        expect(
          calls,
          equals(['syncDispose', 'deleteRemote:test-uid', 'authDelete', 'localCleanup']),
          reason: 'localCleanup 실패: 4단계 모두 호출되어야 한다',
        );
        expect(
          calls.contains('syncReinit'),
          isFalse,
          reason:
              'localCleanup 실패 시 계정이 이미 삭제됐으므로 syncReinit은 호출되지 않아야 한다',
        );
      },
    );
  });
}
