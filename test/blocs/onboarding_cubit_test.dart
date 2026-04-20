import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/blocs/onboarding/onboarding_cubit.dart';
import 'package:clib/services/database_service.dart';

/// `complete()`는 `DatabaseService.setOnboardingComplete` → `preferences` box
/// 에 의존하므로 Hive를 테스트 전용 경로로 초기화한다
/// (ThemeCubit 테스트와 동일한 패턴).
void main() {
  const testHivePath = '.dart_tool/test_hive_onboarding_cubit';

  setUpAll(() async {
    Hive.init(testHivePath);
    await Hive.openBox('preferences');
  });

  setUp(() async {
    await Hive.box('preferences').clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  test('초기 상태는 0', () async {
    final cubit = OnboardingCubit();
    expect(cubit.state, 0);
    await cubit.close();
  });

  test('setPage는 새 인덱스를 emit한다', () async {
    final cubit = OnboardingCubit();
    final emitted = <int>[];
    final sub = cubit.stream.listen(emitted.add);

    cubit.setPage(1);
    cubit.setPage(2);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [1, 2]);

    await sub.cancel();
    await cubit.close();
  });

  test('setPage가 동일 값이면 emit하지 않는다', () async {
    final cubit = OnboardingCubit();
    final emitted = <int>[];
    final sub = cubit.stream.listen(emitted.add);

    cubit.setPage(0);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);

    await sub.cancel();
    await cubit.close();
  });

  test('complete()는 DatabaseService.hasSeenOnboarding을 true로 만든다', () async {
    expect(DatabaseService.hasSeenOnboarding, isFalse);

    final cubit = OnboardingCubit();
    await cubit.complete();

    expect(DatabaseService.hasSeenOnboarding, isTrue);

    await cubit.close();
  });
}
