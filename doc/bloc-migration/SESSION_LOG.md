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
- 실기기 스모크: 미실행 (사용자 측 검증 권장)
- opus `flutter-code-reviewer`: PASS, must-fix 없음

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
