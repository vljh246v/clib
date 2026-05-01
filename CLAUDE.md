# Clib — Agent Guide

> 저장만 하던 습관에서 읽는 습관으로, 스와이프 지식 도서관.
> Flutter(iOS+Android) · local-first(Hive) · 선택적 Firestore 동기화.

이 문서는 **Claude Code 등 에이전트가 본 레포에서 작업할 때 필요한 규칙·함정·진입점**만 담는다. 사양·구조·디자인 토큰 같은 reference는 코드와 `docs/`에 있다 — 중복 금지.

## 1. 진입점

| 의도 | 사용 |
|------|------|
| 새 기능 계획 | `/feature <설명>` |
| 버그 수정 | `/fix <증상>` |
| ARB 키 추가 | `/arb <한국어 → 영어>` |
| Hive 모델 변경 후 | `/build` (`build_runner`) |
| 코드 변경 마무리 | `/check` (analyze + ARB + 모델 정합) |
| 커밋·푸시 | `/push` (사용자 승인 필수) |
| 릴리즈 빌드 | `/release ios|android|both` |

**보조 에이전트** (`Agent` 툴):
- `flutter-code-reviewer` — 커밋/PR 직전 변경분 리뷰. 6단계 재검증 자동화.
- `arb-sync-checker` — ARB 다국어 sync. UI 문자열 추가 후 호출.

**자동 훅** (`.claude/settings.json`): `Write|Edit`로 `.dart` 변경 시 `flutter analyze`가 PostToolUse 훅에서 자동 실행. **수동 재실행 불필요** — `/check` 단계에서만 명시적으로 다시 돌린다.

## 2. 레포 구조 + 참고 문서

```
lib/                 코드 (구조는 docs/architecture.md)
docs/
├── architecture.md  데이터 모델·서비스·부팅 흐름·네이티브 설정
├── conventions.md   코딩·상태관리·디자인 시스템·i18n 워크플로
├── security.md      보안 가드(M-1~M-10 / H-1~H-3) + 운영 절차
├── android-signing-rotation.md   Keystore 로테이션 절차
├── firestore-rules-test-plan.md  Firestore rules 에뮬레이터 테스트
├── aso-listing.md                앱스토어 리스팅
└── archive/                      bloc-migration 등 종료된 작업 산출물
```

`PROJECT_STATE.md` / `DECISION_LOG.md`는 normalized-growth-skill 산출물(랜딩 리뉴얼 스코프). 본 작업과 무관하면 **건드리지 않는다**.

**관련 레포**: `~/Documents/workspace/clib-extension`(Chrome 확장), `~/Documents/workspace/clib-support`(랜딩+개인정보처리).

## 3. 기준 브랜치 / 커밋

- **기준 브랜치는 `develop`** (PR 머지 대상은 `main` 아님).
- 커밋 메시지·코드 주석은 한국어, 한 줄 요약. 성격 다르면 분리 커밋.
- 커밋·푸시는 사용자 승인 후에만. `/push`로 진행.

## 4. 핵심 함정 (코드 읽어도 안 보이는 것)

### 4.1 단일 변경 통로 — DatabaseService

아티클·라벨 mutation은 **반드시 `DatabaseService` 경유**. 직접 `Hive.box()`·`FirestoreService` 접근 금지.

이유: `articlesChangedNotifier`/`labelsChangedNotifier` 발사 책임이 **`DatabaseService` mutation 메서드 + `SyncService` 원격 스냅샷 적용 분기 단독**. Cubit/Bloc·`ShareService`에서 **수동 발사 금지**(중복 reload). Cubit/Bloc은 listener를 `addListener(_onChanged)`/`removeListener` 짝으로 구독한다.

### 4.2 Hive 모델 in-place 변경 → `refreshToken` 패턴

`Article`/`Label`은 `==` 미구현. in-place 변경 후 동일 인스턴스 리스트는 Equatable dedup으로 emit 스킵. 상태 클래스에 `final int refreshToken;` 두고 로드 핸들러마다 증가시켜 stream emit 강제.

### 4.3 `CardSwiper` 재생성 → `deckVersion` 패턴

`CardSwiper(key: ValueKey(state.deckVersion))`. 필터 변경·swipe-read·loop 경계에서 deckVersion++ → 컨트롤러는 `BlocListener.listenWhen: p.deckVersion != c.deckVersion` 가드 + `_pendingDispose` 큐 + `addPostFrameCallback` 일괄 dispose(이중 dispose try-catch).

### 4.4 컨트롤러 SSOT = 위젯 로컬

`TextEditingController`·`CardSwiperController`·`PageController` 등은 **StatefulWidget의 `initState`/`dispose`**에서 관리. **Cubit/Bloc state에 보관 금지**.

### 4.5 다이얼로그/시트 호출 전 cubit 캡처

`showDialog`/`showModalBottomSheet`는 provider scope 이탈. 호출 직전 `final cubit = context.read<X>();` 캡처 후 시트 안에서 캡처본을 사용.

### 4.6 에러 채널 분리

inline 필드 오류(센티넬 코드) / SnackBar 트리거(bool flag 또는 transient nonce + `clearXxx()`) / 원문 메시지(String?) 혼용 금지. `BlocListener.listenWhen` 가드 필수.

### 4.7 HiveField 번호 재사용 금지

추가만 가능. 모델 변경 시 즉시 `/build` (`dart run build_runner build --delete-conflicting-outputs`).

### 4.8 `bloc_test` 미도입

`hive_generator 2.0.1` ↔ `bloc_test`(test 1.16+) 의존성 충돌. 일반 `flutter_test` + `Cubit.stream.listen` + `expectLater` + `await Future<void>.delayed(Duration.zero)` 패턴 사용.

## 5. 상태 관리 정책

- 기본은 **Cubit**. 이벤트 소싱이 명시적으로 필요한 화면만 Bloc — 현재 `HomeBloc` 1개.
- 전역 = `ThemeCubit` + `AuthCubit`(`MultiBlocProvider`, `lib/main.dart`). 그 외 화면 단위 Cubit/Bloc은 화면 진입 시 `BlocProvider`로 주입.
- 모든 state 클래스는 `Equatable` + `copyWith` 필수.

## 6. UI 문자열 / 디자인 토큰 / 다국어

- **UI 문자열 하드코딩 절대 금지** → `AppLocalizations.of(context)!.keyName`. 신규 키는 **10개 ARB 전부**(`ko`(template), `en`(fallback), `de`, `es`, `fr`, `ja`, `pt`, `zh`, `zh_CN`, `zh_TW`)에 동일 키·동일 ICU 플레이스홀더로 추가. 누락 시 빌드 실패 또는 런타임 에러.
- **디자인 토큰 우회 금지**: 색은 `Theme.of(context).colorScheme` 또는 `AppColors`, 간격 `Spacing.*`, 코너 `Radii.*`, 그림자 `AppShadows.*`. 하드코딩 색·매직 넘버 금지.
- 자세한 색상 hex·spacing 값·ARB 워크플로는 `docs/conventions.md`.

## 7. 코드 품질 6단계 (`/check`로 자동화)

모든 코드 변경 후 수행:

1. **영향 범위 파악** — 대상 파일 Read + 참조 grep. 파급 크면 작업 전 공유.
2. **정적 분석** — `flutter analyze` warning/error 0건.
3. **크로스 체크** — import 유효성, 신규 ARB 키 10개 로케일 sync, 모델 변경 시 `build_runner` 실행.
4. **자기 리뷰** — null/await/dispose 누락, setState 남용, 하드코딩, 매직 넘버.
5. **최종 보고** — 한 줄 요약 (예: "analyze 통과, ARB 10개 sync, 영향 범위 HomeScreen만").
6. **커밋 메시지 제안** — 변경 있을 때만, 한국어 한 줄.

## 8. 모델 / 분석 / 자주 까먹는 것

- 모델 변경 → `/build` 즉시. `.g.dart`는 커밋에 포함.
- ARB 변경 → `flutter gen-l10n` 자동 호출됨(`l10n.yaml` 기반). 결과 `lib/l10n/app_localizations*.dart`도 같이 커밋.
- 릴리즈 검증은 **실기기 `flutter run --release`** 필수. 네이티브 시작 경로(스플래시·App Group·MethodChannel)는 디버그·릴리즈 동작이 다를 수 있음.

## 9. 모르겠으면 어디 보나

| 의문 | 위치 |
|------|------|
| 어떤 화면이 어떤 Cubit/Bloc 쓰지? | `docs/architecture.md` §화면 |
| Article/Label 필드? | `lib/models/*.dart` (HiveField 번호 포함) |
| 서비스 책임 경계? | `docs/architecture.md` §서비스 / `lib/services/` |
| 색상·간격 토큰 값? | `lib/theme/design_tokens.dart` / `docs/conventions.md` |
| 보안 위협 / 가드 위치? | `docs/security.md` |
| Android signing? | `docs/android-signing-rotation.md` |
| Firestore rules 검증? | `docs/firestore-rules-test-plan.md` |
| BLoC 마이그레이션 경위? | `docs/archive/bloc-migration/` (완료) |
