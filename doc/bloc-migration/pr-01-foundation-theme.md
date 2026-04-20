# PR 1 — Foundation + ThemeCubit

> 첫 PR. `flutter_bloc` / `equatable` / `bloc_test`를 도입하고, **가장 단순한 테마 설정**을 Cubit으로 전환하여 이후 모든 PR의 패턴을 확립한다.

**의존성**: 없음
**브랜치**: `feature/bloc-01-theme`
**예상 작업 시간**: 1~2시간
**난이도**: ⭐

---

## 1. 목표

- `flutter_bloc ^8.1.6`, `equatable ^2.0.5` 추가 (+ `bloc_test ^9.1.7` dev)
- `lib/blocs/theme/` 디렉토리 신설
- `ThemeCubit` 작성: 초기값 = `DatabaseService.savedThemeMode`, `setTheme(ThemeMode)` 메서드
- `main.dart`의 `themeModeNotifier` 제거
- `MultiBlocProvider`로 전역 주입 (ThemeCubit만 — AuthCubit은 PR 2)
- `MaterialApp.themeMode`를 `BlocBuilder<ThemeCubit>`로 감싸기
- `ThemeSettingsScreen`을 `BlocBuilder`로 교체
- ThemeCubit 유닛 테스트

---

## 2. 사전 요건 (세션 시작 시 Read로 로드할 파일)

| 파일 | 용도 | 필요한 범위 |
|------|------|-------------|
| `pubspec.yaml` | 의존성 추가 위치 확인 | 전체 |
| `lib/main.dart` | `themeModeNotifier` 제거 + MultiBlocProvider 주입 | 전체 |
| `lib/screens/theme_settings_screen.dart` | 교체 대상 | 전체 (70 LOC) |
| `lib/services/database_service.dart:62-75` | `savedThemeMode` / `saveThemeMode` 시그니처 |   |

**알아둘 점**:
- `themeModeNotifier`는 `lib/main.dart:23`에서 정의.
- `DatabaseService.savedThemeMode`는 static getter, `saveThemeMode(ThemeMode)`는 Future\<void\>.
- `ThemeSettingsScreen`은 StatelessWidget + `ValueListenableBuilder` 구조.

---

## 3. 구현 단계

### 3.1 의존성 추가

`pubspec.yaml`에 다음 섹션 수정:

```yaml
dependencies:
  # ... 기존 ...
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

dev_dependencies:
  # ... 기존 ...
  bloc_test: ^9.1.7
```

```bash
flutter pub get
```

### 3.2 ThemeCubit 작성

`lib/blocs/theme/theme_cubit.dart` 신규 생성:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/database_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(DatabaseService.savedThemeMode);

  Future<void> setTheme(ThemeMode mode) async {
    if (mode == state) return;
    await DatabaseService.saveThemeMode(mode);
    emit(mode);
  }
}
```

**주의**: state 자체가 `ThemeMode` enum이라 별도 `State` 클래스 불필요. 단순하기 때문에 이 PR에서는 state 파일을 만들지 않는다. (다른 PR의 Cubit은 대부분 전용 state 클래스 사용.)

### 3.3 main.dart 수정

**Before** (대략 L23 근방):

```dart
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
```

→ **제거**.

**main()** 내부의 `themeModeNotifier.value = DatabaseService.savedThemeMode;` 라인 제거 (ThemeCubit 생성자에서 수행됨).

**ClibApp 빌드** (대략 L83):

**Before**:
```dart
ValueListenableBuilder<ThemeMode>(
  valueListenable: themeModeNotifier,
  builder: (context, mode, _) {
    return MaterialApp(
      // ...
      themeMode: mode,
      // ...
    );
  },
)
```

**After**:
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => ThemeCubit()),
    // PR 2에서 AuthCubit 추가 예정
  ],
  child: BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (context, mode) {
      return MaterialApp(
        // ...
        themeMode: mode,
        // ...
      );
    },
  ),
)
```

**import 추가**:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
```

### 3.4 ThemeSettingsScreen 교체

`lib/screens/theme_settings_screen.dart` 전체 다시 쓰기:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/theme/theme_cubit.dart';
import '../l10n/app_localizations.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeSettings)),
      body: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, current) {
          return ListView(
            children: [
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeSystem),
                value: ThemeMode.system,
                groupValue: current,
                onChanged: (v) =>
                    context.read<ThemeCubit>().setTheme(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeLight),
                value: ThemeMode.light,
                groupValue: current,
                onChanged: (v) =>
                    context.read<ThemeCubit>().setTheme(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeDark),
                value: ThemeMode.dark,
                groupValue: current,
                onChanged: (v) =>
                    context.read<ThemeCubit>().setTheme(v!),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

**주의**: 기존 코드에 쓰이는 ARB 키(`themeSettings`, `themeSystem`, `themeLight`, `themeDark`)를 그대로 재사용한다. 새 키 추가 없음.

### 3.5 settings_screen.dart 경유 참조 확인

`lib/screens/settings_screen.dart`에서 `themeModeNotifier.value`를 직접 읽어 라벨을 표시하는 로직(`_themeModeLabel()`)이 있다.

**Before**:
```dart
Text(_themeModeLabel(themeModeNotifier.value, l10n))
```

**After**:
```dart
BlocBuilder<ThemeCubit, ThemeMode>(
  builder: (context, mode) =>
      Text(_themeModeLabel(mode, l10n)),
)
```

`import '../blocs/theme/theme_cubit.dart';`와 `import 'package:flutter_bloc/flutter_bloc.dart';` 추가.

### 3.6 테스트

`test/blocs/theme_cubit_test.dart` 신규:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/blocs/theme/theme_cubit.dart';
import 'package:clib/services/database_service.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter('test_themes');
    await DatabaseService.init();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  blocTest<ThemeCubit, ThemeMode>(
    'setTheme emits new ThemeMode and persists',
    build: () => ThemeCubit(),
    act: (c) => c.setTheme(ThemeMode.dark),
    expect: () => const [ThemeMode.dark],
    verify: (_) {
      expect(DatabaseService.savedThemeMode, ThemeMode.dark);
    },
  );

  blocTest<ThemeCubit, ThemeMode>(
    'setTheme does not emit when same value',
    build: () {
      // 초기값을 light로 만든 뒤 다시 light 세팅
      DatabaseService.saveThemeMode(ThemeMode.light);
      return ThemeCubit();
    },
    act: (c) => c.setTheme(ThemeMode.light),
    expect: () => const <ThemeMode>[],
  );
}
```

**주의**: `DatabaseService`는 Hive 박스를 사용하므로 테스트에서 `Hive.initFlutter`가 필요. 기존 테스트가 이 세팅을 갖고 있지 않을 수 있으니 처음이라면 `pubspec.yaml`의 dev_dependencies에 `hive_test` 대신 `hive_flutter`를 이미 쓰고 있는지 확인.

만약 `DatabaseService.init()`가 테스트 환경에서 경로 이슈를 일으키면, **테스트는 이 PR에서 스킵**하고 PR 2 이후 Hive 테스트 유틸을 확립한 뒤 다시 추가한다. (핸드오프 노트에 반드시 기록)

---

## 4. 검증

### 4.1 정적 분석 & 테스트

```bash
flutter pub get
flutter analyze           # No issues
flutter test              # 기존 + 신규 블록 테스트 통과
```

### 4.2 실기기 스모크 시나리오

- [ ] 앱 실행 → Settings > 테마 진입
- [ ] System / Light / Dark 순서대로 전환 → 즉시 반영
- [ ] 다른 화면 이동 후 돌아와도 선택 유지
- [ ] 앱 완전 종료 후 재실행 → 마지막 선택 유지 (Hive 저장 확인)
- [ ] `flutter run --release` 1회 실행해 릴리즈 빌드 정상 확인

### 4.3 코드 품질 6단계 (CLAUDE.md 기준)

1. 영향 범위: `main.dart`, `theme_settings_screen.dart`, `settings_screen.dart`만.
2. flutter analyze 0건.
3. 크로스 체크: ARB 변경 없음(기존 키 재사용).
4. 자기 리뷰: `ValueListenableBuilder` 제거 후에도 남은 `themeModeNotifier` 참조가 없는지 `grep "themeModeNotifier"`로 확인.
5. 최종 보고 한 줄 요약.
6. 커밋 메시지 한국어 한 줄.

---

## 5. 커밋 메시지 템플릿

```
BLoC PR1: ThemeCubit 도입 — themeModeNotifier 제거

- flutter_bloc ^8.1.6, equatable ^2.0.5, bloc_test ^9.1.7 추가
- lib/blocs/theme/theme_cubit.dart 신규
- MultiBlocProvider로 ThemeCubit 전역 주입
- ThemeSettingsScreen + SettingsScreen을 BlocBuilder로 교체
- blocs/theme 단위 테스트 추가
```

---

## 6. 흔한 실수

- `BlocProvider.create` 안에서 `ThemeCubit()` 생성 후 바로 `load` 호출? → 불필요. ThemeCubit은 생성자에서 초기값 읽음.
- `main.dart` 외 다른 파일에 남아있는 `themeModeNotifier` 참조 누락 → 컴파일 오류. 빌드 전 grep 확인 필수.
- `BlocBuilder` 없이 `context.read<ThemeCubit>().state`만 쓰면 리빌드 안 됨 → UI에 반영 안 됨.

---

## 7. 핸드오프 노트 (세션 종료 시 작성)

<!-- 이 섹션을 실제 작업 후 채워 넣는다. -->

### 계획대로 된 점
- (세션 후 작성)

### 계획과 다르게 된 점
- (세션 후 작성)

### 새로 발견한 이슈 / TODO
- (세션 후 작성)

### 참고한 링크
- (세션 후 작성)

### 다음 세션 유의사항 (PR 2 또는 다른 PR로 넘어갈 때)
- (세션 후 작성)

### 검증 결과
- `flutter analyze`: (세션 후 작성)
- `flutter test`: (세션 후 작성)
- 실기기 스모크: (세션 후 작성)
