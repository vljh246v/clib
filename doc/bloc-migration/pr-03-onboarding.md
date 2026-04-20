# PR 3 — OnboardingCubit

> 가장 단순한 화면 중 하나. 페이지 인덱스 상태만 들고 있다. Cubit 패턴 숙달용.

**의존성**: PR 1
**브랜치**: `feature/bloc-03-onboarding`
**예상 작업 시간**: 1시간
**난이도**: ⭐

---

## 1. 목표

- `lib/blocs/onboarding/onboarding_cubit.dart` 신규
- `OnboardingScreen`의 `_currentPage` state를 Cubit으로 이동
- `DatabaseService.setOnboardingComplete()` 호출을 Cubit에서 수행
- 유닛 테스트

**비전환 대상** (위젯 local state로 유지):
- `PageController` — 위젯 생명주기와 결합됨

---

## 2. 사전 요건

| 파일 | 범위 |
|------|------|
| `lib/screens/onboarding_screen.dart` | 전체 (283 LOC) |
| `lib/services/database_service.dart:46-60` | setOnboardingComplete 시그니처 |

**핵심 사실**:
- OnboardingScreen은 2가지 모드: `isGuideMode: false`(첫 실행, 완료시 /main 이동), `isGuideMode: true`(설정에서 진입, pop).
- `setState((){ _currentPage = i; })`가 유일한 상태 변경.

---

## 3. OnboardingCubit

`lib/blocs/onboarding/onboarding_cubit.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/database_service.dart';

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  void setPage(int page) {
    if (state != page) emit(page);
  }

  Future<void> complete() async {
    await DatabaseService.setOnboardingComplete();
  }
}
```

**비고**: state가 단순 `int`라 별도 state 클래스 생략 (ThemeCubit과 동일 패턴).

---

## 4. OnboardingScreen 변경

### 4.1 State 제거

- `int _currentPage = 0;` 필드 제거
- setState 제거

### 4.2 BlocProvider

`build()` 최상단:

```dart
@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (_) => OnboardingCubit(),
    child: _OnboardingBody(isGuideMode: isGuideMode),
  );
}
```

`_OnboardingBody`에 기존 화면 내용을 옮기고 `context.read<OnboardingCubit>()`로 접근.

### 4.3 PageView onChanged

**Before**:
```dart
PageView(
  controller: _controller,
  onPageChanged: (i) => setState(() => _currentPage = i),
  children: [...],
)
```

**After**:
```dart
PageView(
  controller: _controller,
  onPageChanged: (i) => context.read<OnboardingCubit>().setPage(i),
  children: [...],
)
```

### 4.4 페이지 인디케이터

**Before**:
```dart
_buildIndicator(_currentPage)
```

**After**:
```dart
BlocBuilder<OnboardingCubit, int>(
  builder: (context, page) => _buildIndicator(page),
)
```

### 4.5 "다음"/"시작하기" 버튼

현재 페이지가 마지막인지 판단 + 완료 액션:

```dart
BlocBuilder<OnboardingCubit, int>(
  builder: (context, page) {
    final isLast = page == 2;
    return FilledButton(
      onPressed: () async {
        if (isLast) {
          if (!isGuideMode) {
            await context.read<OnboardingCubit>().complete();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pop(context);
          }
        } else {
          _controller.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Text(isLast ? l10n.start : l10n.next),
    );
  },
)
```

---

## 5. 테스트

`test/blocs/onboarding_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clib/blocs/onboarding/onboarding_cubit.dart';

void main() {
  blocTest<OnboardingCubit, int>(
    'setPage emits new page index',
    build: () => OnboardingCubit(),
    act: (c) {
      c.setPage(1);
      c.setPage(2);
    },
    expect: () => const [1, 2],
  );

  blocTest<OnboardingCubit, int>(
    'setPage does not emit when same value',
    build: () => OnboardingCubit(),
    act: (c) => c.setPage(0),
    expect: () => const <int>[],
  );
}
```

`complete()` 테스트는 DatabaseService 의존성이 있어 PR 1과 동일하게 Hive init 필요. 없으면 일단 skip.

---

## 6. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크

- [ ] Hive 초기화 직후 첫 실행 시뮬: `DatabaseService.hasSeenOnboarding`를 false로 만들어 재진입 (또는 앱 재설치)
- [ ] 3페이지 스와이프 → 인디케이터 이동 확인
- [ ] 마지막 페이지 "시작하기" → 메인 화면 진입 + 재실행 시 스킵
- [ ] Settings > 사용법 보기 → OnboardingScreen(guide) 진입 → "완료" 시 pop

---

## 7. 커밋 메시지

```
BLoC PR3: OnboardingCubit 도입 — 페이지 인덱스 상태 이동

- lib/blocs/onboarding/onboarding_cubit.dart 신규
- OnboardingScreen._currentPage 제거, BlocBuilder 전환
- setOnboardingComplete 호출을 Cubit으로 이동
```

---

## 8. 핸드오프 노트 (세션 종료 시 작성)

**세션 완료일**: 2026-04-20
**브랜치**: `feature/bloc-03-onboarding` (feature 커밋 `dbf9028`, 머지 커밋 `71acc3c`)

### 계획대로 된 점
- `lib/blocs/onboarding/onboarding_cubit.dart` 신규 — 플랜 스니펫 그대로 (`Cubit<int>` + `setPage` 동일값 가드 + `complete()`)
- `OnboardingScreen._currentPage` 제거 + `setOnboardingComplete()` 호출을 Cubit의 `complete()`로 이동
- 화면 로컬 `BlocProvider` 규칙(README L104) 준수 — 전역 등록 X
- `PageController`는 위젯 local state로 유지 (플랜 2장 "비전환 대상")
- 테스트 4개 PASS (생성자, setPage 변화, 동일값 skip, complete → `hasSeenOnboarding=true`)

### 계획과 다르게 된 점
- **`OnboardingScreen` 구조를 StatefulWidget → StatelessWidget + 내부 `_OnboardingBody(StatefulWidget)` 분리**. 이유: `BlocProvider` 하위에서 `context.read<OnboardingCubit>()`를 쓰려면 provider가 build tree의 하위여야 하는데, 같은 State 안에서는 `_controller` 필드를 유지하면서 read가 불가능. 분리하면 PageController는 body state에 남기고 read도 가능.
- **플랜의 `bloc_test` 사용 스니펫을 PR 1~2 컨벤션(`flutter_test` + `Cubit.stream.listen` + `expectLater`)으로 대체**. PR 1에서 확립된 패턴 일관성 유지.
- **`complete()` 테스트를 skip하지 않고 작성**. Hive `.dart_tool/test_hive_onboarding_cubit` 격리로 `DatabaseService.hasSeenOnboarding` 토글까지 검증.
- **`_onNext/_onSkip/_onComplete`가 `async Future<void>`로 바뀜**. `onPressed`/`GestureDetector`에서 fire-and-forget. 기존 코드(`void _onNext()` 내부에서 `_onComplete()` 호출)도 동일 패턴이었고, `_onComplete` 내부에 `if (!mounted) return;` 가드가 있어 안전.

### 새로 발견한 이슈 / TODO
- `onboarding_screen.dart` line 113 근처 `SizedBox(height: 20)` 매직 넘버 — 기존 코드 유지된 것이며 PR 범위 밖. 추후 레이아웃 정리 PR에서 `Spacing` 토큰 적용 고려.
- OnboardingCubit은 `articlesChangedNotifier`/`labelsChangedNotifier`와 무관(순수 페이지 인덱스) — README L108의 브릿지 규칙 해당 없음.

### 참고한 링크
- flutter_bloc BlocProvider scoping: https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider
- PR 1~2 선례: `lib/blocs/theme/theme_cubit.dart`, `test/blocs/theme_cubit_test.dart`

### 다음 세션 유의사항
- **PR 4(LibraryCubit)**: `articlesChangedNotifier`/`labelsChangedNotifier` 브릿지 패턴을 처음 적용하는 PR. README L108 템플릿 확인 필수.
- **화면 로컬 BlocProvider + State 분리 패턴**: StatefulWidget 내부에서 read가 필요하면 `_XxxBody(StatefulWidget)` 분리를 기본 선택지로. PR 3에서 확립.
- **Cubit 단위 테스트 컨벤션**: `flutter_test` + `Cubit.stream.listen` + `expectLater`. `bloc_test` 패키지는 여전히 미도입 (플랜 문서의 스니펫은 무시).
- **Hive 테스트 격리 path**: `.dart_tool/test_hive_<name>` + `setUpAll(openBox)` + `setUp(clear)` + `tearDownAll(deleteFromDisk)` 패턴 고정.

### 검증 결과
- `flutter analyze`: ✅ No issues found
- `flutter test test/blocs/`: ✅ 17/17 passed (theme 3 + auth_state 10 + onboarding 4)
- 실기기 스모크: ⚪ 사용자 요청 시에만 진행 (미수행)
- `flutter-code-reviewer`(opus): LGTM — BlocProvider 위치·BlocBuilder 범위·dispose 안전·PR 1~2 컨벤션 일관
