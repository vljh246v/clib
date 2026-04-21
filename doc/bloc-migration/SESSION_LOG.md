# 세션 핸드오프 로그

> 각 세션의 **결과 요약**과 **다음 세션 유의사항**을 누적 기록한다.
> 세션 종료 시 반드시 엔트리를 추가한다.
>
> PR 1~9 + 세션 0 엔트리는 [`archive/SESSION_LOG_PR1-9.md`](./archive/SESSION_LOG_PR1-9.md)
> 로 분리(머지 완료, 회고 참조용).

## 현 상태 요약 (2026-04-21 PR 11 §2.6 widget_test 재작성 직후)

- **완료**: PR 1~9 머지 + PR 11 §2.1~2.5 / §2.7~2.9(develop 머지) +
  §2.6 widget_test 재작성(`feature/bloc-11-widget-test`).
- **남은 PR 11 작업**: §3 실기기 회귀 스모크 17개 항목(`pr-11-cleanup.md` §3) —
  사용자 수행. 완료 시 트래커 🟢.
- **PR 10**: ⚪ Skip 확정 (`archive/pr-10-main-optional.md`).
- **검증 기준선**: `flutter analyze` 0건, `flutter test` **77 PASS**
  (74 bloc + 3 widget smoke).

---

## 엔트리 템플릿

````markdown
## <YYYY-MM-DD> PR <NN> — <제목>

**세션 결과**: 🟢 완료 / 🟡 부분 완료 / 🔴 블록됨 / ⚪ 미착수
**브랜치**: `feature/bloc-NN-slug` (커밋 SHA)

### 계획대로 된 점
### 계획과 다르게 된 점
### 새로 발견한 이슈 / TODO
### 다음 세션 유의사항
### 검증 결과
- `flutter analyze`: ✅ / ❌
- `flutter test`: ✅ N passed / ❌
- 실기기 스모크: ✅ / ⚠️ / ⏳
````

---

## 로그 (최신 위)

## 2026-04-21 PR 11 §2.6 — widget_test 재작성 + hive_bootstrap 헬퍼

**세션 결과**: 🟢 완료 (§3 실기기 스모크는 사용자 수행 대기)

**브랜치**: `feature/bloc-11-widget-test` (develop 기반, 신규 커밋 예정)

### 계획대로 된 점
- **`test/helpers/hive_bootstrap.dart` 추출**: `HiveTestHarness(pathName)` 클래스.
  `setUpAll`에서 격리 path + 어댑터 등록(중복 방지 가드) + 3박스 open.
  `setUp`에서 박스 clear + `DatabaseService.skipSync = true` + notifier 리셋.
  `tearDownAll`에서 `Hive.deleteFromDisk()`. `seedArticle` / `seedLabel`
  헬퍼도 포함해 기존 블록 테스트와 동일 패턴을 위젯 테스트에서도 재사용.
- **`test/widget_test.dart` 재작성**: 3 케이스 모두 PASS.
  - `HiveTestHarness`가 articles/labels/preferences 3박스를 연다.
  - 다음 테스트 진입 시 이전 시드가 제거된다(setUp의 clear 확인).
  - `AppLocalizations` delegate 가 한국어 로케일로 `library` 키를
    "보관함"으로 해석한다.
- **검증**: `flutter analyze` 0건, `flutter test` **77 PASS**
  (기존 74 bloc + 3 widget smoke).

### 계획과 다르게 된 점
- **`MainScreen` / `HomeScreen` / `LibraryScreen` 실화면 렌더 테스트 포기**:
  - `ClibApp`은 `Firebase.initializeApp()` + `AuthCubit`(lazy:false) +
    `ShareService`(네이티브 채널)에 의존해 테스트 환경에서 띄울 수 없다.
  - `LibraryScreen`을 단독으로 `MaterialApp`에 싸서 렌더해도 빈 DB는 통과하지만,
    라벨 1개 이상 시드된 상태에서 `pump` / `pumpAndSettle` 모두 수렴하지 않고
    5분+ 행(원인 미확정 — `CustomPaint(_CircularProgressPainter)` 포함
    `GridView` + BlocBuilder 조합 추정).
  - Cubit/Bloc 동작 자체는 `test/blocs/*_test.dart` 74 케이스로 이미 커버되어
    위젯 트리 렌더 검증은 실기기 스모크(`pr-11-cleanup.md` §3)로 위임.
- **Firebase mock 패키지 도입 불필요**: 스모크 범위를 Hive + l10n으로 축소하니
  Firebase 경로를 타지 않음.

### 새로 발견한 이슈 / 후속 PR 후보
- **LibraryScreen 실화면 렌더 hang 재현**: 단일 라벨 카드가 포함된 `GridView`
  + `CustomPaint` + BlocBuilder 조합에서 `pump`/`pumpAndSettle` 무한 대기.
  재현 코드는 이 커밋에서 widget_test 에서 제거됐지만, flutter_test 환경에서
  재현 가능하므로 별도 조사 이슈로 추적 가능.
- **NotificationService ARB 통합**, **`_SwipeHint` 색 일관성**, **Repository
  계층** 등 기존 후보는 그대로 유효.

### 다음 세션 유의사항
1. **§3 실기기 스모크 17 항목** — 사용자 수행(`flutter run --release`).
   - notifier 발사 일원화 + bulkDelete batch 회귀 포인트 필수.
2. 스모크 완료 후 `feature/bloc-11-widget-test` → develop 머지 +
   `README.md` 트래커 🟢 + `SESSION_LOG.md` 완료 엔트리 추가.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test`: ✅ 77 passed (74 bloc + 3 widget)
- 실기기 스모크: ⏳ 사용자 수행 대기

---

## 2026-04-21 PR 11 — Cleanup (코드/문서 정리)

**세션 결과**: 🟡 부분 완료 (코드/문서 7 커밋 완료, §2.6 widget_test + §3 실기기 스모크는 다음 세션)

**브랜치**: `feature/bloc-11-cleanup` — 커밋 7개:
- `51ecd9f` (1/7) notifier 발사 경로 DatabaseService 일원화 + bulkDelete batch
- `913e7e6` (2/7) home_screen 디자인 토큰 + AdService.adInterval 상수화 + dispose 보강
- `149da17` (3/7) showBulkDeleteConfirm 헬퍼 + ArticleListItem.accentColor + 타입 좁힘
- `01f0ed9` (4/7) 미사용 ARB 키 syncing/syncComplete 제거 (10 로케일)
- `a229204` (5/7) pubspec.yaml environment.flutter floor 명시
- `deb6b2e` (6/7) CLAUDE.md flutter_bloc 기반 구조 갱신
- `01c4a78` (7/7) doc/bloc-migration PR 11 핸드오프

### 계획대로 된 점
- **Notifier 발사 경로 일원화**: `DatabaseService` 모든 mutation에
  `articlesChangedNotifier` / `labelsChangedNotifier` 발사 추가.
  `ShareService.processAndSave` 중복 발사 제거.
  `HomeBloc._onToggleBookmark/_onUpdateMemo` / `ArticleListCubit` 개별 액션의
  수동 reload 호출 제거 — listener 경로 단일화.
- **Notifier 정의 분리**: `lib/state/app_notifiers.dart` 신규.
  `main.dart`는 `export 'package:clib/state/app_notifiers.dart' show ...`로
  호환 유지(기존 `package:clib/main.dart` show ... import 그대로 동작).
- **컨트롤러 dispose 보강**: `HomeScreen._showMemoDialog`(whenComplete),
  `share_label_sheet._showAddLabelDialog`, `label_management_screen._showLabelDialog`.
- **디자인 토큰 치환**: `home_screen` 일반 spacing 12/16/8/4/20을 `Spacing.*`로,
  `BorderRadius.circular(20)` → `Radii.borderXl`. 26/28/36/120 등 의도 사이즈는
  인라인 유지.
- **`adInterval = 8` 단일 출처화**: `AdService.adInterval` 상수.
  `home_screen._adInterval` + `article_list_view` 둘 다 참조.
- **`_confirmBulkDelete` 헬퍼 추출**: `lib/widgets/bulk_delete_confirm.dart`의
  `showBulkDeleteConfirm(context)`. 3화면 중복 제거.
- **`ArticleListItem.accentColor` 옵션** + `ArticleListView.accentColor` 패스스루.
  `LabelDetailScreen`이 `_labelColor` 전달 → 라벨 색이 행 뱃지에 반영.
- **`selectedKeys` 타입 좁힘**: `List<dynamic>` → `List<int>`.
  `ArticleListView.onSelectionToggle(int)` 시그니처도 좁힘.
- **`bulkDelete` batch**: `DatabaseService.bulkDelete(articles)` 신규
  (`_box.deleteAll(keys)` + 단일 notifier 발사).
- **미사용 ARB 정리**: `syncing` / `syncComplete` 2개 키를 10 로케일 전부에서
  제거. `flutter gen-l10n` 재생성. NotificationService 4개 키는 보존.
- **`pubspec.yaml`**: `environment.flutter: ">=3.32.0"` floor 명시.
- **`CLAUDE.md`**: 기술 스택 + 프로젝트 구조 + 전역 상태 섹션 + 화면별 로직 +
  §상태 관리 규칙 신설.

### 계획과 다르게 된 점
- **`LabelManagementCubit` 개별 액션의 직접 `await load()` 유지**:
  `try/finally`로 `isSaving` 토글 → emit 시점에 articles 갱신 미반영 위험.
  안전 우선으로 유지.
- **`AddArticleCubit.createLabel`도 직접 fetch + emit 유지**:
  첫 emit에서 `selectedLabels` 업데이트가 동시 필요(listener는 allLabels만 갱신).
  결과는 두 번 emit이지만 동일.
- **`HomeBloc._onSwipeRead`는 즉시 articles 제거 + deckVersion++ 유지**:
  notifier listener의 후속 LoadDeck(resetPosition:false)는 deckVersion 변화
  없음 → CardSwiper 재생성 1회로 안전.
- **`_SwipeHint` 왼쪽 색 변경 보류**: 체크리스트는 "검토". 디자인 의도
  사용자 결정 필요. 별도 PR/이슈로 분리.
- **`syncing` / `syncComplete` 외 미사용 ARB 키 4개 보존**:
  NotificationService 구조적 제약(BuildContext 없음).
  정리하려면 `lookupAppLocalizations(Locale)` + 정적 헬퍼 도입 필요 → 별도 PR.
- **§2.6 widget_test / §3 실기기 스모크**: 분량 한도 + 사용자 A안(코드 우선).
  다음 세션 위임.

### 새로 발견한 이슈 / 후속 PR 후보
- **NotificationService ARB 통합 PR**: `notificationChannelName/Desc`,
  `allReadNotification`, `unreadNotification` 4개 키를
  `lookupAppLocalizations(Locale.fromSubtags(Platform.localeName))`로 끌어쓰면
  다국어 자산 단일 출처. 현재는 ko/en switch 하드코딩 + ARB 잉여 공존.
- **`_SwipeHint` 색 일관성**: `theme.colorScheme.onSurfaceVariant`(왼쪽) vs
  `AppColors.swipeRead`(오른쪽) / `AppColors.swipeSkip`. 디자인 의도 확인 후 결정.
- **`bulk_action_bar.onDelete` 콜백 시그니처를
  `Future<void> Function(BuildContext)`로 승격**하면 `() => helper(context)`
  클로저 3곳 제거 가능.
- **이중 emit (Advisor 우려 #2)**: `ArticleListCubit.bulkXxx` 후 listener +
  `_reloadAndClearSelection` 두 번 emit. 동기 실행이라 시각 영향 없고
  `isSelecting` listenWhen 트리거 없음. 비용 미미. 향후 깔끔히 하려면
  listener detach 토큰 또는 selection 관리만 별도 emit으로 분리.

### 다음 세션 유의사항 (가장 중요)

1. **§2.6 widget_test 재작성**:
   - `test/helpers/hive_bootstrap.dart` 추출(setUpAll에서 임시 path +
     ArticleAdapter/LabelAdapter/PlatformAdapter 등록 + box open, setUp에서
     clear + `DatabaseService.skipSync = true`, tearDownAll에서 deleteFromDisk).
   - Firebase 초기화 mock 또는 skip 결정 (mock 패키지 도입 vs 분기).
   - `MainScreen` / `HomeScreen` 스모크 수준이면 충분.
   - 기존 `test/widget_test.dart`는 PR 1 이전부터 broken이라 자유롭게 재작성.
2. **§3 실기기 회귀 스모크** (`pr-11-cleanup.md` §3, 17 항목):
   - notifier 발사 일원화 + bulkDelete batch가 핵심 회귀 포인트.
   - **반드시 검증**: 다중 선택 일괄 삭제/북마크/읽음, 라벨 변경 후 모든
     화면 동기 갱신, 공유 시트 → 라벨 선택 → 저장 후 홈 즉시 반영.
   - `flutter run --release` 실기기 + Firestore 동기화 + 계정 삭제 포함.
3. **위 둘 완료 후**: 트래커 🟢 + PR 11 머지 + `develop` push.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/`: ✅ 74 passed
- 실기기 스모크: ⏳ §3 다음 세션
