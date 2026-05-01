# BLoC 점진적 전환 — 마스터 문서 (Archived)

> **상태: 완료. 본 폴더는 history 보존용 아카이브.**
> 마이그레이션 결과로 정착된 패턴(컨트롤러 SSOT, `refreshToken`, `deckVersion`,
> 에러 채널 분리 등)은 `/CLAUDE.md` §4 / `docs/conventions.md` §2에 정식 정의되어 있다.
> 현재 코드와 다를 수 있는 항목이 있으니 **운영 규칙은 CLAUDE.md를 우선** 참조.
>
> Clib 상태 관리를 `setState` + `ValueNotifier`에서 `flutter_bloc`(Cubit 중심)으로
> **화면 단위로 점진 전환**한 장기 작업의 기록.

## 활성 문서 (이 폴더)

| 문서 | 역할 |
|------|------|
| `README.md` | 본 문서 — 진행 트래커 + 활성 작업 인덱스 |
| `SESSION_STARTER.md` | 새 세션 진입점 — 즉시 해야 할 일 |
| `SESSION_LOG.md` | 세션 핸드오프 로그 (PR 11 ~ 현재) |
| `pr-11-cleanup.md` | 진행 중인 PR 11 (Cleanup) 체크리스트 |
| `archive/` | PR 1~10 완료 문서 + PR 1~9 SESSION_LOG 보존 |

전체 아키텍처 결정: `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md`

---

## 진행 현황 트래커

| PR | 제목 | 상태 | 브랜치 | 완료일 |
|----|------|------|--------|--------|
| 1 | Foundation + ThemeCubit | 🟢 Done | `feature/bloc-01-theme` | 2026-04-20 |
| 2 | AuthCubit + SyncService 이관 | 🟢 Done | `feature/bloc-02-auth` | 2026-04-20 |
| 3 | OnboardingCubit | 🟢 Done | `feature/bloc-03-onboarding` | 2026-04-20 |
| 4 | LibraryCubit | 🟢 Done | `feature/bloc-04-library` | 2026-04-20 |
| 5 | LabelManagementCubit | 🟢 Done | `feature/bloc-05-label-mgmt` | 2026-04-20 |
| 6 | ArticleListCubit + AllArticles | 🟢 Done | `feature/bloc-06-article-list` | 2026-04-21 |
| 7 | Bookmarked + LabelDetail (재사용) | 🟢 Done | `feature/bloc-07-bookmarked-label` | 2026-04-21 |
| 8 | AddArticleCubit | 🟢 Done | `feature/bloc-08-add-article` | 2026-04-21 |
| 9 | HomeBloc (유일한 Bloc) | 🟢 Done | `feature/bloc-09-home` | 2026-04-21 |
| 10 | MainScreen ShareFlowCubit | ⚪ Skip | - | - |
| 11 | Cleanup + 문서화 | 🟡 In Progress | `feature/bloc-11-cleanup` | 2026-04-21 (코드/문서) |

상태 기호: ⬜ Not Started / 🟡 In Progress / 🟢 Done / 🔴 Blocked / ⚪ Skip

---

## 현재 상태 (2026-04-21 PR 11 코드/문서 정리 완료)

- **브랜치**: `feature/bloc-11-cleanup`, 7 커밋 (`51ecd9f` ~ `01c4a78`)
- **검증**: `flutter analyze` 0건, `flutter test test/blocs/` **74 PASS**
- **남은 작업** (다음 세션, `pr-11-cleanup.md` §2.6 + §3):
  1. `test/widget_test.dart` 재작성 + `test/helpers/hive_bootstrap.dart` 헬퍼 추출
  2. 실기기 회귀 스모크 17개 항목
  3. 위 둘 완료 후 PR 11 머지 + 트래커 🟢

자세한 핸드오프(계획대로/계획과 다르게/후속 PR 후보)는 `SESSION_LOG.md` PR 11 엔트리.

---

## PR 11 변경 요약 (코드/문서)

### 코드 변경
- `lib/state/app_notifiers.dart` 신규 — notifier 정의 분리(순환 import 회피).
  `main.dart`는 호환을 위해 re-export.
- `DatabaseService` 모든 mutation 메서드가 `articles/labelsChangedNotifier`
  발사 단독 책임. `bulkDelete(articles)` batch 신규.
- `ShareService.processAndSave` 중복 발사 제거.
- `HomeBloc` / `ArticleListCubit` 개별 액션 수동 reload 제거 — listener 경로
  단일화.
- `home_screen` 디자인 토큰 치환 + `BorderRadius.circular(20)` →
  `Radii.borderXl`. `AdService.adInterval = 8` 단일 출처화.
- `ArticleListItem.accentColor` 옵션 + `ArticleListView.accentColor` 패스스루.
  LabelDetail이 `_labelColor` 전달.
- `selectedKeys: List<dynamic>` → `List<int>` 좁힘. `onSelectionToggle(int)`도.
- `_confirmBulkDelete` 3화면 중복 → `lib/widgets/bulk_delete_confirm.dart` 헬퍼.
- 컨트롤러 dispose 보강 (`HomeScreen` MemoDialog, `share_label_sheet`,
  `label_management_screen`).
- 미사용 ARB 키 `syncing` / `syncComplete` 10 로케일 제거.
- `pubspec.yaml` `environment.flutter: ">=3.32.0"` floor.

### 문서 변경
- `CLAUDE.md` — 기술 스택 + 프로젝트 구조 + 전역 상태 섹션 + 화면별 로직 +
  §상태 관리 규칙 신설.
- `archive/` 디렉토리 신설 — 머지 완료 PR 1~10 문서 + PR 1~9 SESSION_LOG 보존.
- 활성 `README.md` / `SESSION_LOG.md` / `SESSION_STARTER.md` 압축.

---

## 후속 PR 후보 (PR 11 외, 별도 작업)

| 후보 | 내용 |
|------|------|
| NotificationService ARB 통합 | 4개 키(`notificationChannelName/Desc`, `allReadNotification`, `unreadNotification`)를 `lookupAppLocalizations(Locale.fromSubtags(Platform.localeName))`로 끌어쓰기 |
| `_SwipeHint` 색 일관성 결정 | 왼쪽 `onSurfaceVariant` vs `swipeSkip(Muted Rose)` 디자인 의도 확인 |
| `bulk_action_bar.onDelete` 시그니처 승격 | `Future<void> Function(BuildContext)`로 → `() => helper(context)` 클로저 3곳 제거 |
| Repository 계층 도입 검토 | Cubit/Bloc → DatabaseService 직접 호출 → Repository 추상화 시 mock/테스트 격리 용이 |
| Hive Stream 전환 검토 | `Box.watch()` 또는 `ValueListenableBuilder<Box<Article>>`로 전환 시 ValueNotifier 브릿지 자체 제거 가능 |

---

## 공통 규칙 (PR 11 이후 신규 작업 시 참조)

### 상태 관리 (CLAUDE.md §상태 관리 규칙 정식 정의)

- 기본 Cubit. 이벤트 소싱이 명시적으로 필요한 화면만 Bloc(현재 `HomeBloc` 1개).
- 전역 BlocProvider = `ThemeCubit` + `AuthCubit`. 나머지 화면 로컬.
- 상태 클래스 = `Equatable` + `copyWith` 필수.
- 컨트롤러는 위젯 로컬 SSOT (`TextEditingController`/`CardSwiperController`/
  `PageController` 등).
- Hive in-place 변경 대응 = `refreshToken` / `generation` 필드로 emit 강제.
- CardSwiper 재생성 = `key: ValueKey(state.deckVersion)` + `_pendingDispose`
  큐 + `addPostFrameCallback` 일괄 dispose.
- 다이얼로그/시트 호출 전 `final cubit = context.read<X>()` 캡처.
- 에러 채널 분리 = inline 센티넬 / SnackBar bool flag / 원문 String? 혼용 금지.

### 검증 3단계 (모든 PR 공통)

1. `flutter analyze` — No issues
2. `flutter test test/blocs/` — 통과
3. 실기기 스모크 — 해당 PR 체크리스트

### 코드 품질

- CLAUDE.md "코드 품질 & 재검증" 6단계 준수
- `flutter-code-reviewer` 서브에이전트 호출 권장(커밋 전)
- ARB 수정 시 `arb-sync-checker` 호출

### Cubit/Bloc 파일 구조

```
lib/blocs/<domain>/
├── <domain>_cubit.dart       # 또는 <domain>_bloc.dart
├── <domain>_state.dart
└── <domain>_event.dart       # Bloc인 경우만
```

### 패키지 버전 (PR 1에서 고정)

- `flutter_bloc: ^8.1.6`
- `equatable: ^2.0.5`
- `bloc_test: ^9.1.7` (dev) — **현재 미도입**
  (`hive_generator 2.0.1` ↔ `bloc_test`(test 1.16+) 충돌, 일반 `flutter_test`
  + `Cubit.stream.listen` 패턴 사용)

---

## 참고 링크

- flutter_bloc: https://bloclibrary.dev/
- Cubit vs Bloc: https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc
- Equatable: https://pub.dev/packages/equatable
- 프로젝트 규칙: `/CLAUDE.md`
- 전체 플랜: `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md`
