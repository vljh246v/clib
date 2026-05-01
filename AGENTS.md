# Clib Agent Guide

> Codex/Claude 등 에이전트가 작업 시작 전에 읽는 최소 운영 규칙.
> 상세 구조·컨벤션·보안 설명은 `docs/`를 우선한다.

## 먼저 볼 문서

| 필요 | 위치 |
|------|------|
| 구조, 모델, 서비스, 부팅 흐름 | `docs/architecture.md` |
| 코딩 규칙, 상태관리, 디자인 토큰, i18n | `docs/conventions.md` |
| 보안 체크포인트 | `docs/security.md` |
| Android signing | `docs/android-signing-rotation.md` |
| Firestore rules 검증 | `docs/firestore-rules-test-plan.md` |
| 종료된 작업 기록 | `docs/archive/` |

`PROJECT_STATE.md`와 `DECISION_LOG.md`는 랜딩 리뉴얼 관련 산출물이다. 관련 작업이 아니면 건드리지 않는다.

## 작업 규칙

- 기준 브랜치는 `develop`. PR 머지 대상은 `main`이 아니다.
- 커밋 메시지와 코드 주석은 한국어 한 줄 요약을 기본으로 한다.
- 커밋·푸시는 사용자 승인 후에만 한다.
- 기존 변경사항은 사용자 작업으로 간주하고 되돌리지 않는다.
- Claude Code 전용 자동화는 `.claude/commands/`, `.claude/agents/`, `.claude/settings.json`에 있다. Codex에서는 같은 의도를 직접 수행한다.

## 반드시 지킬 것

### 데이터 변경 경로

- `Article`/`Label` mutation은 반드시 `DatabaseService`를 통한다.
- 화면, Cubit/Bloc, `ShareService`에서 `Hive.box(...)`나 `FirestoreService`를 직접 쓰지 않는다.
- `articlesChangedNotifier`/`labelsChangedNotifier` 발사는 `DatabaseService` mutation과 `SyncService` 원격 스냅샷 적용 분기만 맡는다.
- Cubit/Bloc은 notifier를 `addListener`로 구독하고 `close()`에서 반드시 해제한다.

### 상태/UI 패턴

- 기본은 Cubit, 이벤트 소싱이 필요한 화면만 Bloc. 현재 예외는 `HomeBloc`.
- 모든 state는 `Equatable` + `copyWith`를 유지한다.
- `TextEditingController`, `CardSwiperController`, `PageController` 등 컨트롤러는 위젯 로컬 `State`에서 생성·해제한다. Bloc/Cubit state에 넣지 않는다.
- `showDialog`/`showModalBottomSheet` 호출 전 `context.read<X>()`를 캡처해 시트/다이얼로그에 넘긴다.
- Hive 객체 in-place 변경 후 emit이 필요하면 `refreshToken` 패턴을 쓴다.
- `CardSwiper` 덱 재생성이 필요하면 `deckVersion` + `ValueKey` 패턴을 쓴다.
- inline 오류, SnackBar 트리거, 원문 메시지는 state에서 채널을 분리한다.

### 모델, 문자열, 디자인

- `HiveField` 번호는 재사용하지 않는다. 모델 변경 후 `dart run build_runner build --delete-conflicting-outputs`.
- UI 문자열은 `AppLocalizations.of(context)!.keyName`만 사용한다. 새 키는 10개 ARB 전체에 동일 키·동일 ICU 플레이스홀더로 추가한다.
- 색/간격/코너/그림자는 `Theme`, `AppColors`, `Spacing`, `Radii`, `AppShadows` 토큰을 사용한다.
- `bloc_test`는 도입하지 않는다. `flutter_test` + stream 구독 패턴을 쓴다.

### 보안 영향

- 새 URL 입력 경로는 스킴 화이트리스트와 SSRF/OOM 가드를 확인한다.
- Firestore 필드/컬렉션 변경은 rules와 에뮬레이터 검증 계획을 같이 본다.
- 계정/세션 변경은 계정 전환 wipe와 탈퇴 실패 복구 경로를 확인한다.
- 로그는 `print` 대신 릴리즈 가드된 logging 경로를 사용하고 식별자를 마스킹한다.

## 검증

변경 범위에 맞춰 실행한다.

- 일반 코드 변경: `flutter analyze`, 관련 `flutter test`
- ARB 변경: 10개 로케일 키/플레이스홀더 동기화 확인, 필요 시 `flutter gen-l10n`
- Hive 모델 변경: `dart run build_runner build --delete-conflicting-outputs`
- 릴리즈/네이티브 경로 변경: 실기기 `flutter run --release`

검증하지 못한 항목은 최종 보고에 명시한다.
