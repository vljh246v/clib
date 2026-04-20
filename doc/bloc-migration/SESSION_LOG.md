# 세션 핸드오프 로그

> 각 세션의 **결과 요약**과 **다음 세션 유의사항**을 누적 기록한다. 세션 종료 시 반드시 엔트리를 추가한다.

## 엔트리 템플릿

아래 템플릿을 복사해서 **최상단**에 붙여 넣는다(최신이 위).

````markdown
## <YYYY-MM-DD> PR <NN> — <제목>

**세션 결과**: 🟢 완료 / 🟡 부분 완료 / 🔴 블록됨 / ⚪ 미착수

**브랜치**: `feature/bloc-NN-slug` (커밋 SHA: `abc1234`)

### 계획대로 된 점
- ...

### 계획과 다르게 된 점
- (예: "StatefulBuilder를 없애려 했는데 다이얼로그 상태가 꼬여서 유지하기로 함")
- (예: "equatable 대신 dart 3의 sealed + pattern matching 사용")

### 새로 발견한 이슈 / TODO
- ...

### 참고한 링크
- ...

### 다음 세션 유의사항
- (중요!) 이 섹션이 가장 중요. 다음 세션이 반드시 알아야 할 것만.
- (예: "PR 6에서 도입한 ArticleListCubit.source enum이 byLabel(name)에서 이스케이프 문제 있음. PR 7 시작 시 먼저 확인할 것.")

### 검증 결과
- `flutter analyze`: ✅ No issues / ❌ (이슈 내용)
- `flutter test`: ✅ N passed / ❌ (실패 내용)
- 실기기 스모크: ✅ / ⚠️ (특이사항)
````

---

## 로그 (최신 위)

<!-- 이 아래에 세션 엔트리를 추가한다. 최신이 위. -->

## 2026-04-20 PR 02 — AuthCubit

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-02-auth` (feature 커밋: `22e3702`, 머지 커밋: `ce44d23`)

### 계획대로 된 점
- `lib/blocs/auth/auth_cubit.dart` + `auth_state.dart` 신규 (플랜 스니펫과 거의 동일)
- `FirebaseAuth.authStateChanges` 구독 + `SyncService.init/dispose` 책임을 AuthCubit으로 이관
- `main.dart`에서 `authStateNotifier` 전역 제거 + 직접 listen 블록 + 초기 currentUser 처리 제거
- `MultiBlocProvider`에 `AuthCubit(lazy: false)` 추가
- `SettingsScreen`: `ValueListenableBuilder<User?>` → `BlocBuilder<AuthCubit, AuthState>`, 4개 핸들러 `context.read<AuthCubit>()` 경유로 교체
- `AuthState` copyWith + equality 유닛 테스트 10개 PASS

### 계획과 다르게 된 점
- **AuthCubit 자체 유닛 테스트 미작성**: Firebase 의존으로 PR 11(firebase_auth_mocks 도입 시)로 위임. 플랜 9.1에서 허용한 범위.
- **`_onAuthChanged` try/catch 래핑**: 리뷰어 nit 반영. `SyncService.init/dispose`에서 예외가 터지더라도 `isInitialized=true` emit이 보장되어야 `SettingsScreen`이 `SizedBox.shrink()`에 영구히 머무는 상태를 방지.
- **`close()`에서 `await _sub.cancel()`**: 리뷰어 nit 반영. 대칭성/안전성 개선.
- **`main.dart`에서 `firebase_auth` import 제거**: `FirebaseAuth.instance.currentUser == null` → `!AuthService.isLoggedIn`로 치환. 의도적 정리.
- **runApp 타이밍**: 기존 `await SyncService.init(currentUser)`가 runApp 이전에 끝나던 것이, 신규는 AuthCubit 생성자 이후 비동기 실행. 초기 HomeScreen은 Hive 데이터 먼저 렌더 → Firestore 첫 스냅샷이 덮어씀. 치명적 레이스 없음.

### 새로 발견한 이슈 / TODO
- **AuthState.copyWith(setUserNull)** 패턴은 기능 OK지만 sentinel/Optional 대비 덜 명시적. PR 11에서 재고려 가능.
- **`AuthService.isLoggedIn` 활용 확산**: 앞으로도 `FirebaseAuth.instance.currentUser` 직접 의존은 `AuthService` 경유로 정리 권장.
- **(공통 컨벤션 재확인)** cubit 테스트 작성 규칙: Firebase 의존 없으면 full coverage, 의존 있으면 상태 객체 테스트만 → PR 11 mocks 도입 전까지 동일.

### 참고한 링크
- flutter_bloc: https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc
- `FirebaseAuth.authStateChanges()` 첫 이벤트 시멘틱 (구독 시 현재 user 재발행)

### 다음 세션 유의사항
- **PR 3(OnboardingCubit)**: 난이도 ⭐, 가장 단순. state가 `int` 하나라 `Cubit<int>` 패턴(ThemeCubit과 동일).
- **전역 BlocProvider 규칙** (README L104): 전역 = ThemeCubit, AuthCubit. OnboardingCubit은 **화면 로컬** `BlocProvider`.
- **Hive 테스트 격리 path 컨벤션** 동일: `.dart_tool/test_hive_onboarding_cubit`.
- **기존 `test/widget_test.dart`**: 여전히 broken(pre-existing). PR 11 위임.
- **CLAUDE.md/플랜 문서의 `themeModeNotifier`/`authStateNotifier` 잔존 언급**: PR 11 cleanup 확정, 무시.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/`: ✅ 13/13 passed (AuthState 10 + ThemeCubit 3)
- `flutter test`(전체): ⚠️ +13 / -1, 실패 1건은 pre-existing `widget_test.dart` (PR 11 위임, 회귀 아님)
- 시뮬레이터/실기기 스모크: 미실행 (사용자 요청 없음)
- opus `flutter-code-reviewer`: PASS, 0 must-fix, nit 2건 반영

### 머지 / 배포
- `develop` 머지(--no-ff): `ce44d23` (`Merge feature/bloc-02-auth: BLoC PR 2 — AuthCubit 도입`)
- `origin/develop` push 완료 (`bd0e45b..ce44d23`)
- `feature/bloc-02-auth` 브랜치 보존

### 다음 세션 즉시 시작 프롬프트 (PR 3 — OnboardingCubit)

다음 세션 시작 시 아래 프롬프트를 그대로 복사해 사용:

````
doc/bloc-migration/pr-03-onboarding.md를 정독하고 PR 3(OnboardingCubit) 작업을 시작해줘.
이전 세션(PR 2) 결과는 SESSION_LOG.md 최상단에 있어. 아래 컨벤션을 반드시 따를 것.

## PR 1~2에서 확립된 컨벤션

1. **bloc_test 미도입**: cubit 단위 테스트는 일반 `flutter_test` + `Cubit.stream.listen` + `expectLater`
2. **테스트 Hive 격리 path**: `setUpAll`에서 `Hive.init('.dart_tool/test_hive_<name>')` + `openBox`, `tearDownAll`에서 `deleteFromDisk`
3. **전역 vs 화면 로컬 BlocProvider** (README L104): 전역 = ThemeCubit + AuthCubit. **OnboardingCubit은 화면 로컬** `BlocProvider`(OnboardingScreen.build 최상단).
4. **CLAUDE.md/플랜 문서의 잔존 언급 무시**: `themeModeNotifier`/`authStateNotifier` — PR 11 cleanup 위임 확정.
5. **브랜치 워크플로**: `develop ↔ origin/develop` 동기화 확인 후 `feature/bloc-03-onboarding` 분기 → `--no-ff` 머지 + push (PR 생성 X, 사용자 승인 후 push)
6. **서브에이전트 모델**: 단순 haiku / 분석 sonnet / 최종 리뷰만 opus `flutter-code-reviewer`
7. **시뮬레이터 스모크**: 사용자가 요청할 때만 진행
8. **기존 `test/widget_test.dart`는 broken**: PR 11 위임

## PR 3 시작 시 즉시 할 일

1. `git status` + `develop`/`origin/develop` 동기화 확인
2. `doc/bloc-migration/pr-03-onboarding.md` 정독 + `lib/screens/onboarding_screen.dart`(283 LOC) Read
3. `git checkout -b feature/bloc-03-onboarding`
4. `flutter analyze` 기준선 확인
5. 작업 계획 한 줄 요약 + 영향 범위 보고 후 시작

## PR 3 알려진 주의사항 (pr-03-onboarding.md 정독 전 참고)

- OnboardingCubit은 state가 `int` 하나(페이지 인덱스) → 별도 state 클래스 없이 `Cubit<int>` (ThemeCubit과 동일 패턴)
- `PageController`는 위젯 생명주기 결합으로 로컬 state 유지 (비전환 대상)
- `isGuideMode`에 따라 완료 동작 분기 (false → /main push + setOnboardingComplete, true → Navigator.pop)
- `DatabaseService.setOnboardingComplete()` 호출을 Cubit의 `complete()`로 이동
````

---

## 2026-04-20 PR 01 — Foundation + ThemeCubit

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-01-theme` (커밋 SHA: `b7a5dcc`)

### 계획대로 된 점
- `flutter_bloc ^8.1.6`, `equatable ^2.0.5` 도입
- `lib/blocs/theme/theme_cubit.dart` 신규 (persist 후 emit, idempotency 가드)
- `themeModeNotifier` lib/ 전체에서 0건으로 제거
- `MultiBlocProvider`로 ThemeCubit 전역 주입
- `ThemeSettingsScreen` + `SettingsScreen`을 BlocBuilder/`context.watch`로 교체
- 단위 테스트 3개 PASS

### 계획과 다르게 된 점
- **bloc_test 9.x 미도입**: `hive_generator 2.0.1`(analyzer ≤7) ↔ `bloc_test`(test 1.16+ → analyzer 8+) 충돌. 일반 `flutter_test` + `Cubit.stream` + `expectLater`로 대체. 결과 동등.
- **`ThemeSettingsScreen` 디자인/ARB 보존**: 플랜 스니펫의 단순 ListView 대신 기존 `RadioGroup<ThemeMode>`+Container shadow 구조를 유지하고 ValueListenableBuilder만 BlocBuilder로 치환. ARB 키는 실제 사용 중인 `theme/systemSettings/darkMode/lightMode`로 유지.
- **테스트 환경**: `DatabaseService.init()`(path_provider 의존) 우회를 위해 `Hive.init('.dart_tool/test_hive_theme_cubit')`+`openBox('preferences')` 직접 호출. `_prefsBox` getter라 호환됨.

### 새로 발견한 이슈 / TODO
- **(공통 컨벤션)**: 후속 모든 cubit 테스트는 격리 path + `setUpAll`/`tearDownAll`에서 명시적 init/deleteFromDisk.
- **CLAUDE.md L103/L107**의 `themeModeNotifier` 설명은 PR 11 cleanup으로 위임됨.
- **기존 `test/widget_test.dart`는 PR 1 이전부터 broken** (Firebase·Hive 미초기화). PR 1 회귀 아님(stash 사전 확인). PR 11에서 테스트 헬퍼와 함께 재작성 권장.
- **`pubspec.yaml`에 `environment.flutter` floor 없음**: `RadioGroup<T>` 신규 API(Flutter 3.32+) 명시화 검토 필요(현재 dev 환경 통과).
- **bloc_test 재시도 시점**: hive 4.x 또는 hive_ce_generator 도입 시.

### 참고한 링크
- flutter_bloc: https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc
- 의존성 충돌 분석: `flutter pub deps --no-dev` + `flutter pub get` 에러 메시지

### 다음 세션 유의사항
- **PR 2(AuthCubit)**: `main.dart:82` 근방 `MultiBlocProvider.providers`에 `AuthCubit` 추가만 하면 됨. ThemeCubit과 동일 패턴.
- **bloc_test 없이** 기존 `flutter_test`로 cubit 검증 — PR 2 이후 모든 cubit 동일.
- **Hive 테스트 컨벤션** 위 TODO 그대로 적용.
- **CLAUDE.md/플랜 문서의 `themeModeNotifier` 잔존 언급**은 의도된 deferral, PR 11까지 무시.
- **현재 브랜치**: `feature/bloc-01-theme`. PR 2는 develop으로 머지 후 다시 develop에서 분기하거나, PR 2 브랜치를 PR 1에 base로 stack 가능. 사용자 결정 사항.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/theme_cubit_test.dart`: ✅ 3/3 passed
- `flutter test`(전체): ⚠️ 신규 3 PASS / 기존 widget_test 1 FAIL(pre-existing, 회귀 아님)
- 시뮬레이터 스모크(iPhone 17, iOS 26.4, debug): ✅ 첫 프레임 + 테마 토글/유지 OK
- 실기기 release 스모크: 미실행 (사용자 권장)
- opus `flutter-code-reviewer`: PASS, must-fix 없음

### 머지 / 배포
- `develop` 머지(--no-ff): `f592689` (`Merge feature/bloc-01-theme: BLoC PR 1 — ThemeCubit 도입`)
- `origin/develop` push 완료 (`0bc7fc7..f592689`)
- `feature/bloc-01-theme` 브랜치는 보존 (히스토리/리퍼런스용)

### 다음 세션 즉시 시작 프롬프트 (PR 2 — AuthCubit)

다음 세션 시작 시 아래 프롬프트를 그대로 복사해 사용:

````
doc/bloc-migration/pr-02-auth.md를 정독하고 PR 2(AuthCubit) 작업을 시작해줘.
이전 세션(PR 1) 결과는 SESSION_LOG.md 최상단에 있어. 아래 컨벤션을 반드시 따를 것.

## PR 1에서 확립된 컨벤션 (PR 2 이후 모두 적용)

1. **bloc_test 미도입**: `hive_generator 2.0.1` ↔ `bloc_test 9.x`(test 1.16+ → analyzer 8+) 의존성 충돌. cubit/bloc 단위 테스트는 일반 `flutter_test` + `Cubit.stream.listen` + `expectLater`로 작성. 효과 동일.
2. **테스트 Hive 우회**: 각 테스트 파일은 격리 path 사용 — `setUpAll`에서 `Hive.init('.dart_tool/test_hive_<name>')` + 필요 box `openBox`, `tearDownAll`에서 `Hive.deleteFromDisk`. `DatabaseService.init()`은 path_provider 의존이라 단위 테스트에서 호출 불가. `_prefsBox` 등은 getter라 직접 openBox만 해도 호환됨.
3. **MultiBlocProvider 확장**: `lib/main.dart` `ClibApp.build` 안의 기존 `MultiBlocProvider.providers`에 `AuthCubit` `BlocProvider`만 append. ThemeCubit과 동일 패턴.
4. **CLAUDE.md/플랜 문서의 `themeModeNotifier` 잔존 언급은 무시**(PR 11 cleanup으로 위임 확정).
5. **브랜치 워크플로**: `develop`이 `origin/develop`과 동기화 확인 후 `feature/bloc-02-auth` 분기 → 작업/커밋 → 머지는 `--no-ff` + 사용자 승인 후 push (PR 생성 없음).
6. **서브에이전트 모델**: 단순 작업 haiku, 분석/판단 sonnet, 최종 리뷰만 `opus` 모델로 `flutter-code-reviewer` 호출.
7. **시뮬레이터 스모크**: 사용자가 "버추얼머신 테스트"라고 요청하면 진행. 빌드는 약 7분 소요(첫 빌드 기준).
8. **기존 `test/widget_test.dart`는 broken**: PR 11에서 헬퍼와 함께 재작성 예정. PR 2에서 우회/수정 시도하지 말 것.

## PR 2 시작 시 즉시 할 일

1. `git status` + `git rev-list --left-right --count develop...origin/develop` 동기화 확인
2. `doc/bloc-migration/pr-02-auth.md` 정독 + 사전 요건 파일들 Read
3. `git checkout -b feature/bloc-02-auth`
4. `flutter analyze`로 기준선 No issues 확인
5. 작업 계획 한 줄 요약 + 영향 범위 보고 후 사용자 승인 받고 시작

## PR 2 알려진 주의사항 (pr-02-auth.md 정독 전 참고)

- `lib/main.dart`의 `authStateNotifier`(L32 부근)와 `FirebaseAuth.instance.authStateChanges()` 리스너, `SyncService.init/dispose` 호출이 AuthCubit 책임으로 이관됨
- `lib/services/auth_service.dart`의 static API는 유지(라이트 스코프)
- `lib/screens/settings_screen.dart`의 `ValueListenableBuilder<User?>(valueListenable: authStateNotifier)`는 `BlocBuilder<AuthCubit, ...>`로 교체 필요
- 데모 데이터 시드 / Firebase 초기화 순서 / pending share 처리와의 race 조건 주의
````

---

## 2026-04-20 세션 0 — 문서 체계 구축

**세션 결과**: 🟢 완료

**브랜치**: main (문서만 추가, 별도 브랜치 불필요)

### 계획대로 된 점
- `doc/bloc-migration/` 하위에 README, SESSION_STARTER, SESSION_LOG, PR 1~11 문서를 모두 생성
- 마스터 플랜은 `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md`에 유지
- 진행 현황 트래커 + PR 단위 상세 문서 구조 확립

### 계획과 다르게 된 점
- 해당 없음 (신규 문서화만 수행)

### 새로 발견한 이슈 / TODO
- PR 1 시작 전: `flutter --version` + `flutter pub outdated`로 의존성 호환성 사전 확인 권장 (pubspec.yaml의 sdk: ^3.11.4 와 flutter_bloc 8.x 호환)

### 참고한 링크
- flutter_bloc 문서: https://bloclibrary.dev/

### 다음 세션 유의사항
- **세션 0 이후의 첫 구현 세션은 PR 1부터 시작**
- PR 1 문서(`pr-01-foundation-theme.md`) 읽은 뒤 바로 구현 가능
- 현재 브랜치는 main, 작업 트리 clean 상태

### 검증 결과
- `flutter analyze`: ✅ No issues (문서 변경만)
- `flutter test`: 미실행 (코드 무변경)
- 실기기: N/A
