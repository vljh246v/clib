import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/blocs/theme/theme_cubit.dart';
import 'package:clib/services/database_service.dart';

/// path_provider를 우회하기 위해 Hive.init(path)를 직접 사용.
/// DatabaseService.init()은 Hive.initFlutter()를 호출해 테스트 환경에서 동작하지 않음.
void main() {
  const testHivePath = '.dart_tool/test_hive_theme_cubit';

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

  test('초기 상태는 DatabaseService.savedThemeMode를 읽는다', () async {
    final cubit = ThemeCubit();
    expect(cubit.state, ThemeMode.system);
    await cubit.close();
  });

  test('setTheme은 새 값을 emit하고 persist한다', () async {
    final cubit = ThemeCubit();
    final emitted = <ThemeMode>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.setTheme(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [ThemeMode.dark]);
    expect(DatabaseService.savedThemeMode, ThemeMode.dark);

    await sub.cancel();
    await cubit.close();
  });

  test('setTheme이 동일 값이면 emit하지 않는다', () async {
    await DatabaseService.saveThemeMode(ThemeMode.light);
    final cubit = ThemeCubit();
    expect(cubit.state, ThemeMode.light);

    final emitted = <ThemeMode>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.setTheme(ThemeMode.light);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);

    await sub.cancel();
    await cubit.close();
  });
}
