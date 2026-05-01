# Conventions

> 코딩·상태관리·디자인 시스템·i18n 워크플로. 운영 규칙은 `/AGENTS.md`, 구조·서비스는 `architecture.md`.

## 1. 코딩 일반

- 한국어 주석/커밋 메시지. 한 줄 요약.
- UI 문자열 하드코딩 금지 → `AppLocalizations.of(context)!.keyName` (자세히 §4).
- 디자인 토큰 우회 금지 → 색·간격·코너·그림자 (자세히 §3).
- 매직 넘버 금지(0/1/2/-1/100% 제외). 의미 있으면 named constant.
- `print` 금지 → `debugPrint`. 릴리즈 가드(M-8). 개인 식별자(UID 등) 마스킹.
- `flutter analyze` = No issues 유지(`Write|Edit` 훅이 자동 실행 — `/check`에서만 명시 재실행).
- 모델 변경 → `dart run build_runner build --delete-conflicting-outputs`.
- 릴리즈 검증은 실기기 `flutter run --release`.

## 2. 상태 관리 (`flutter_bloc`)

### 2.1 골격

- 기본 = **Cubit**. 이벤트 소싱이 명시적으로 필요한 화면만 **Bloc**(현재 `HomeBloc` 1개).
- 전역 `MultiBlocProvider` = `ThemeCubit` + `AuthCubit`. 그 외 화면 진입 시 `BlocProvider`로 주입.
- 모든 state 클래스 = `Equatable` + `copyWith` 필수.
- 파일 구조:
  ```
  lib/blocs/<domain>/
  ├── <domain>_cubit.dart       (또는 <domain>_bloc.dart)
  ├── <domain>_state.dart
  └── <domain>_event.dart       (Bloc인 경우만)
  ```

### 2.2 컨트롤러 = 위젯 로컬 SSOT

`TextEditingController`/`CardSwiperController`/`PageController` 등은 **StatefulWidget의 `initState`/`dispose`**에서 관리. **Cubit/Bloc state에 보관 금지.**

### 2.3 Hive in-place 변경 → `refreshToken` 패턴

`Article`/`Label`은 `==` 미구현 → in-place 변경 후 동일 인스턴스 리스트는 Equatable dedup으로 emit 스킵. 상태 클래스에 `final int refreshToken;` 두고 로드 핸들러에서 매번 증가시켜 stream emit 강제.

### 2.4 `CardSwiper` 재생성 → `deckVersion` 패턴

`CardSwiper(key: ValueKey(state.deckVersion))`. 필터 변경/swipe-read/loop 경계에서 deckVersion++ → 컨트롤러는 `BlocListener.listenWhen: p.deckVersion != c.deckVersion` 가드 후 `_pendingDispose` 큐 + `addPostFrameCallback` 일괄 dispose(이중 dispose 방지 try-catch).

### 2.5 다이얼로그/시트 호출 전 cubit 캡처

```dart
final cubit = context.read<X>();
showModalBottomSheet(context: context, builder: (_) => Sheet(cubit: cubit));
```
`showDialog`/`showModalBottomSheet`는 provider scope 이탈 — 캡처 안 하면 sheet 안에서 `context.read<X>()` 실패.

### 2.6 에러 채널 분리

| 종류 | 표현 |
|------|------|
| inline 필드 오류 | 센티넬 코드(예: `urlError: 'EMPTY'/'INVALID'/null`) |
| SnackBar 트리거 | bool flag 또는 transient nonce + `clearXxx()` (소비 후 reset) |
| 원문 메시지 | String? |

혼용 금지. `BlocListener.listenWhen` 가드 필수.

### 2.7 `bloc_test` 미도입

`hive_generator 2.0.1` ↔ `bloc_test`(test 1.16+) 충돌. 다음 패턴 사용:

```dart
final cubit = MyCubit();
final states = <MyState>[];
final sub = cubit.stream.listen(states.add);
cubit.doThing();
await Future<void>.delayed(Duration.zero);
expect(states, [...]);
await sub.cancel();
```

## 3. 디자인 시스템

방향: **Calm & Refined** (Notion, Things 3 영감). 폰트: Pretendard 5 weight(Regular~ExtraBold).

### 3.1 컬러 (`lib/theme/app_theme.dart` `AppColors`)

| 토큰 | Light | Dark |
|------|-------|------|
| Primary | Warm Charcoal `#2C2C3A` | Soft Lavender `#A8B5D6` |
| Secondary(accent) | Sage Green `#5BA67D` | Soft Sage `#7DC4A0` |
| Error | Muted Rose `#E8726E` | Soft Rose `#E8857F` |
| Background | `#F8F7F4` | `#141416` |
| Surface / Container | `#FFFFFF` / `#F2F1EE` | `#1C1C1E` / `#242426` |
| OnSurface / Variant | `#1C1C1E` / `#8E8E93` | `#E5E5EA` / `#8E8E93` |
| swipeRead / swipeSkip | Sage Green / Muted Rose (공용) | |

### 3.2 디자인 토큰 (`lib/theme/design_tokens.dart`)

- **Spacing**: `xs(4) / sm(8) / md(12) / lg(16) / xl(20) / xxl(24) / xxxl(32)`
- **Radii**: `sm(8) / md(12) / lg(16) / xl(20) / full(100)` + 사전계산 `BorderRadius` 상수
- **AppShadows**: `card(isDark)`, `swipeCard(isDark)`, `navigation(isDark)` — 이중 레이어
- **AppDurations**: `fast(150) / medium(250) / slow(350)`
- **LabelColors.presets**: 10색 (채도 낮은 톤)

### 3.3 사용 규칙

- 색은 `Theme.of(context).colorScheme` 또는 `AppColors`. `Color(0x...)`/`Colors.red` 금지.
- 간격은 `Spacing.*`. `EdgeInsets.all(17)` 같은 매직 넘버 금지.
- 코너는 `Radii.*`. 그림자는 `AppShadows.*`.
- 색상 외 이미지·아이콘은 모드별 자산 분리 또는 `Theme.of(context).brightness` 분기.

## 4. 다국어 (i18n)

### 4.1 방식

Flutter 공식 `gen-l10n` (ARB, `l10n.yaml` 템플릿=`app_ko.arb`).

**지원 로케일(10)**: `ko`(기본/템플릿), `en`(fallback), `de`, `es`, `fr`, `ja`, `pt`, `zh`, `zh_CN`, `zh_TW`. 시스템 언어 자동 감지. iOS Settings > Clib / Android 13+ Settings > Clib에서 앱별 언어 변경.

### 4.2 워크플로

1. `lib/l10n/app_ko.arb`에 한국어 키-값 추가 (필요 시 `@키` 메타 + `placeholders`).
2. **나머지 9개 ARB**(en, de, es, fr, ja, pt, zh, zh_CN, zh_TW)에 동일 키 추가. **누락 시 빌드 실패**.
3. `flutter gen-l10n` 자동 실행됨 (`pubspec.yaml`의 `generate: true` + l10n.yaml).
4. 코드: `AppLocalizations.of(context)!.keyName`.

`/arb <한국어 → 영어>` 슬래시 커맨드로 단계 자동화. 보조 에이전트 `arb-sync-checker`로 sync 검증.

### 4.3 ICU 플레이스홀더 일관성

```json
"selectedCount": "{count}개 선택됨",
"@selectedCount": { "placeholders": { "count": { "type": "int" } } }
```

**ko/en을 포함한 모든 로케일 파일에 동일 키·동일 플레이스홀더**가 있어야 한다. 다르면 런타임 에러.

### 4.4 BuildContext 없는 경로

`NotificationService`는 BuildContext 없이 `dart:io` `Platform.localeName`으로 로케일 판단 → 한국어면 한국어, 그 외는 영어 메시지. (후속 후보: `lookupAppLocalizations(Locale.fromSubtags(Platform.localeName))`로 통합)

## 5. 코드 품질 6단계 (`/check`)

`/AGENTS.md` §검증 참조. 요약:

1. 영향 범위 — Read + grep
2. `flutter analyze` 0건 (훅 자동 실행 — 명시 재실행은 이 단계에서만)
3. 크로스 체크 — import / ARB 10 sync / 모델 변경 시 `build_runner`
4. 자기 리뷰 — null/await/dispose/setState/하드코딩/매직 넘버
5. 한 줄 보고
6. 한국어 커밋 메시지 제안

보조: `flutter-code-reviewer` 에이전트(커밋/PR 직전), `arb-sync-checker` 에이전트(ARB 변경 후).

## 6. 네이밍

- 함수/변수: `camelCase`. 클래스: `PascalCase`. private: `_` 접두.
- 파일: `snake_case.dart`. 단일 화면당 폴더 두지 말고 `lib/blocs/<domain>/` + `lib/screens/<screen>.dart` + `lib/widgets/<widget>.dart` 평면 유지.
- ARB 키: `camelCase`. 화면명/맥락 접두 권장(`homeFilterAll`, `addArticleSaveFailure`).
- 슬래시 커맨드 / 에이전트 / settings.json hook 이름은 영문 kebab-case.
