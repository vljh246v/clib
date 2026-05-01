# SESSION_LOG Archive (PR 1~9 + 세션 0)

> PR 1~9 + 세션 0 단계 핸드오프 로그 보존본. 모두 머지 완료된 작업이라
> 활성 `SESSION_LOG.md`에서 분리. 회고/패턴 참조용.
>
> PR 11 이후 신규 엔트리는 활성 `SESSION_LOG.md`에 추가한다.
>
> 관련 PR 문서도 `archive/pr-0N-*.md`에 보존되어 있다.

---

## 2026-04-21 PR 09 — HomeBloc (유일한 Bloc)

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-09-home` (feature 커밋: `5a94a98`, docs 커밋: `5874113`, 머지 커밋: `68a1edb`)

### 계획대로 된 점
- `lib/blocs/home/{home_bloc,home_event,home_state}.dart` 신규. 시리즈 유일 Bloc.
- `HomeScreen`을 `StatelessWidget(BlocProvider)` + `_HomeBody(StatefulWidget)`으로 분리. `CardSwiperController` / `_pendingDispose` / `_thresholdNotifier` 위젯 로컬 SSOT.
- `deckVersion` ValueKey로 CardSwiper 재생성 — 인덱스 out-of-range 방지.
- `articlesChangedNotifier` / `labelsChangedNotifier` 생성자 addListener, close() removeListener.
- home_bloc_test 14건 신규 — 전체 블록 테스트 74 PASS.

### 계획과 다르게 된 점
- **필터 AND 유지**: plan 스니펫은 OR(`any`) — 기존 `_selectedLabels.every` UX 회귀 방지 위해 AND로 구현.
- **`HomeEditLabels` 이벤트 드롭**: `LabelEditSheet`가 이미 `updateArticleLabels`를 persist → 이중 호출 방지. 시트 await 후 `HomeLoadDeck(resetPosition: false)` 단순 재로드.
- **`HomeSwipeLater.reachedEnd` 플래그 추가**: 기존 `currentIndex == null` 루프 경계 리셋 동작 보존. reachedEnd=true일 때만 `deckVersion++` emit(DB 무변경).
- **`HomeSwipeRead`에서 deckVersion++ 추가**: plan은 articles 제거만, isLoop+numberOfCardsDisplayed=3 조건에서 out-of-range 리스크 → 덱 재생성으로 안전성 확보.
- **`refreshToken` 필드 추가(리뷰 should-fix)**: `Article`은 Hive 모델 + `==` 미구현 → in-place 변경된 articles 리스트 재로드가 Equatable dedup으로 emit 스킵될 위험. 매 `_onLoad`마다 `refreshToken++`로 stream emit 강제. 현시점 UI 경로에선 시각적 회귀 없으나 북마크 뱃지/메모 미리보기 추가 시 조용한 갱신 실패 리스크 선제 차단.
- **`bloc.isClosed` 가드(nit)**: `LabelEditSheet.show` await 후 dispatch 경로.

### 새로 발견한 이슈 / TODO
- **`_showMemoDialog` TextEditingController dispose 미호출**(기존 관례). PR 11 시트 공통화 시 정리.
- **하드코딩 숫자/색상 잔존**: `BorderRadius.circular(20)`, 120/56/36/28/26/16/12 — 기존 선행. PR 11 cleanup 대상.
- **`_SwipeHint` 왼쪽 색**: `onSurfaceVariant` 사용. `swipeSkip=Muted Rose` 공용 토큰과 불일치(기존부터). 디자인 의도 확인 후 결정.
- **초기 `_swiperController` 한 인스턴스 낭비**: initState에서 생성 → 첫 emit(0→1)에서 즉시 pendingDispose 이관. 누수 아님.
- **`labelsChangedNotifier` 로컬 CRUD 미발사**(PR 8에서도 이관): `DatabaseService.createLabel/updateLabel/deleteLabel` 미발사. PR 11 통합.

### 참고한 링크
- `DatabaseService.markAsRead` `lib/services/database_service.dart:116` (notifier 미발사 확인)
- `DatabaseService.updateArticleLabels` `lib/services/database_service.dart:364`
- `LabelEditSheet.show` + 내부 persist `lib/widgets/label_edit_sheet.dart:19,184`
- 발사원: `ShareService.processAndSave`(`share_service.dart:68`) + `SyncService` 원격 스냅샷(`sync_service.dart:276`)
- flutter_bloc BlocConsumer: https://bloclibrary.dev/flutter-bloc-concepts/#blocconsumer

### 다음 세션 유의사항 (PR 10 선택 / PR 11 Cleanup)
- **PR 10**: MainScreen ShareFlowCubit. 기본 SKIP. 현 `WidgetsBindingObserver` + `ShareService.checkPendingShares` 경로 단순.
- **PR 11(권장 다음)**: Cleanup + 문서화. 누적 후속 정리:
  1. `labelsChangedNotifier` 로컬 CRUD 통합 발사
  2. `articlesChangedNotifier` 발사 경로 일원화(`DatabaseService` 내부로 승격)
  3. 시트 `TextEditingController` 라이프사이클(MemoDialog 등)
  4. 하드코딩 숫자/색상 디자인 토큰 치환
  5. 기존 `test/widget_test.dart` 재작성(PR 1부터 broken)
  6. `themeModeNotifier` / `authStateNotifier` CLAUDE.md 잔존 언급 제거
- **컨벤션 불변**(PR 1~9): bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 컨트롤러 위젯 로컬 SSOT / refreshToken 패턴(Hive in-place 변경 대응) / 서브에이전트 병렬 dispatch / 시뮬레이터 스모크 사용자 요청 시만.

### 검증 결과
- `flutter analyze`: ✅ No issues (2.0s)
- `flutter test test/blocs/home_bloc_test.dart`: ✅ 14/14 PASS
- `flutter test test/blocs/`: ✅ 74 PASS (기존 60 + 신규 14)
- 실기기 스모크: ⚪ 사용자 방침(전 PR 정리 후 일괄)
- opus `flutter-code-reviewer`: must-fix 0, should-fix 1(refreshToken 반영), nit 1(bloc.isClosed 반영), nit 3건 범위 외 이관

### 머지 / 배포
- feature 커밋: `5a94a98` (BLoC PR9: HomeBloc 도입 — 스와이프/필터/덱 관리 이벤트 소싱)
- docs 커밋: `5874113` (docs(bloc): PR 9 완료 핸드오프 노트 + SESSION_LOG + README 트래커 업데이트)
- **develop 머지**: `68a1edb` (`--no-ff` Merge feature/bloc-09-home)
- **origin push 완료**: `feature/bloc-09-home` 최초 push, `develop` 8c8cbef..68a1edb
- 브랜치 보존: `feature/bloc-09-home`

### 다음 세션 즉시 시작 프롬프트 (PR 11 — Cleanup 권장)

```
doc/bloc-migration/pr-11-cleanup.md 정독하고 PR 11(Cleanup + 문서화) 작업 시작.
이전 세션(PR 9 HomeBloc) 결과는 SESSION_LOG.md 최상단. 아래 컨벤션 준수.

## PR 1~9 확립 컨벤션

1. bloc_test 미도입: flutter_test + Cubit.stream.listen + expectLater + await Future<void>.delayed(Duration.zero)
2. Hive 격리 path: setUpAll에서 .dart_tool/test_hive_<name>, 어댑터 등록, setUp clear + skipSync=true, tearDownAll deleteFromDisk
3. 전역 BlocProvider = ThemeCubit + AuthCubit만. 나머지 화면 로컬
4. TextEditingController/CardSwiperController/PageController 등 위젯 생명주기 결합 컨트롤러는 StatefulWidget 로컬 SSOT
5. Bloc/Cubit의 Event+State는 Equatable, state는 copyWith 필수
6. 다이얼로그/시트 호출 **전** final cubit = context.read<X>() 캡처
7. articlesChangedNotifier/labelsChangedNotifier 중복 발사 금지: DB 서비스 내부 발사 경로 확인 후 Bloc에서 추가 발사 X
8. Hive in-place 변경 시 Equatable dedup 회피용 refreshToken 패턴(PR 9 도입)
9. 브랜치 워크플로: develop ↔ origin/develop 동기화 → feature/bloc-11-cleanup 분기 → feature 커밋 → docs 커밋 → --no-ff develop 머지 → 사용자 승인 후 push
10. 서브에이전트 병렬 dispatch: haiku(단순) / sonnet(로직) / opus(flutter-code-reviewer 최종)
11. 시뮬레이터 스모크: 사용자 요청 시만 — PR 11에서 전체 플로우 일괄 검증 권장

## PR 11 누적 후속 정리 리스트 (pr-11-cleanup.md + 본 로그 확인)

1. labelsChangedNotifier 로컬 CRUD 통합 발사(DatabaseService.createLabel/updateLabel/deleteLabel)
2. articlesChangedNotifier 발사 경로 일원화(DatabaseService 내부 승격 검토)
3. 시트 TextEditingController 라이프사이클 정리(HomeScreen._showMemoDialog 외)
4. 하드코딩 숫자/색상 디자인 토큰 치환
5. 기존 test/widget_test.dart 재작성(PR 1부터 broken)
6. themeModeNotifier/authStateNotifier CLAUDE.md 잔존 언급 제거
7. PR 9 범위 외 nit: _SwipeHint 왼쪽 색 swipeSkip 토큰 검토
```

---

## 2026-04-21 PR 08 — AddArticleCubit

**세션 결과**: 🟢 완료 (develop 머지 + push 완료)

**브랜치**: `feature/bloc-08-add-article` (feature 커밋: `69b77cf`, docs 커밋: `6849649`, 머지 커밋: `14910bb`)

### 계획대로 된 점
- `lib/blocs/add_article/{cubit,state}.dart` 신규. Equatable + copyWith 표준 패턴.
- `AddArticleSheet` 347 LOC StatefulWidget → `show()` 정적 메서드 전용 클래스 + `_AddArticleBody(StatefulWidget)` 분리. TextEditingController만 위젯 로컬 SSOT.
- `BlocProvider` 화면 로컬 주입, `BlocConsumer.listenWhen` 3채널 가드(isDone/saveFailure/labelErrorMessage).
- URL 검증 `Uri.tryParse + hasScheme + host.isNotEmpty` 유지(기존 UX).
- `labelsChangedNotifier` 구독/해제 대칭. `articlesChangedNotifier`는 `ShareService.processAndSave` 내부 발사 경로 존중(중복 금지).
- 11 테스트 PASS (state copyWith 4 + cubit 7). 전체 블록 테스트 60 PASS.

### 계획과 다르게 된 점
- **`url` state 필드 드롭**: PR 8 문서 스니펫은 url: String을 state에 포함했으나 TextEditingController와 이중 SSOT 회피. Cubit은 `urlError` 센티넬만, `save(rawUrl)`로 URL 전달.
- **`ShareService.extractURL` 검증 미채택**: 기존 엄격 Uri 검증 유지(정규식은 너무 관대).
- **에러 채널 3분리 (리뷰 must-fix 반영)**: 초기 `failureMessage: String?` 단일 필드 → 저장 실패(`saveFailed` i18n) ↔ 라벨 생성 실패(원문 메시지) 의미가 달라 SnackBar 매핑 회귀 발견 → `saveFailure: bool` + `labelErrorMessage: String?` 분리.
- **`AddArticleSheet` private ctor (리뷰 should-fix 반영)**: 초기 StatelessWidget + 중복 `BlocProvider`는 dead code. `show()`가 유일 진입점이라 `class AddArticleSheet { const AddArticleSheet._(); static Future<void> show(...) }` 로 정리.
- **`_showAddLabelDialog` 책임 축소**: 다이얼로그는 (name, color) 선택만, 생성은 Cubit.`createLabel(name, color)`로 위임. 실패 시 원문 listener → SnackBar.
- **`DatabaseService.createLabel`이 `Label` 반환**하므로 `getAllLabelObjects().firstWhere(...)` 재조회 제거.

### 새로 발견한 이슈 / TODO
- **`labelsChangedNotifier` 로컬 CRUD 미발사**: `DatabaseService.createLabel/updateLabel/deleteLabel`는 `labelsChangedNotifier.value++` 미발사. `SyncService` 원격 스냅샷(`sync_service.dart:392`)만 발사. AddArticleSheet이 열린 동안 다른 화면에서 라벨이 바뀌어도 `_refreshLabels` 트리거 안 됨. PR 11 또는 별도 PR로 로컬 CRUD 발사 통합 필요.
- **하드코딩 매직 넘버 보존**: 핸들바/칩 사이즈/알파값. 디자인 토큰 미적용. PR 11 cleanup 대상.
- **`nameController` lifecycle** (기존 코드 유지분): 시트 dismiss 시 Future null 완료로 dispose 도달. 회귀 아님.

### 참고한 링크
- `DatabaseService.createLabel` 시그니처: `database_service.dart:234`
- `ShareService.processAndSave` 발사 경로: `share_service.dart:67-68` (`articlesChangedNotifier.value++`)
- flutter_bloc BlocConsumer: https://bloclibrary.dev/flutter-bloc-concepts/#blocconsumer

### 다음 세션 유의사항 (PR 9 — HomeBloc)
- **PR 9는 시리즈 유일한 `Bloc`**. swipe 이벤트(`markAsRead`/`skip`/`undo`) + deck 상태 + `CardSwiperController` 재생성이 이벤트 기반이라 Bloc 적합.
- **의존성**: PR 1 + PR 6(ArticleListCubit). 재사용 판단 필요 — Home deck은 미읽음 스트리밍이라 소스가 다름. 별도 HomeBloc 권장.
- **복잡성**: `CardSwiperController` 이중 dispose 방지, 8카드마다 `SwipeAdCard`, 오버레이 가이드, `addPostFrameCallback` 컨트롤러 교체 패턴 그대로 유지.
- **컨벤션 불변** (PR 1~8): bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 서브에이전트 병렬 dispatch / 시뮬레이터 스모크 사용자 요청 시만.

### 검증 결과
- `flutter analyze`: ✅ No issues (2.0s)
- `flutter test test/blocs/`: ✅ 60 PASS (기존 49 + 신규 11)
- 실기기 스모크: ⚪ 사용자 방침(전 PR 정리 후 일괄)
- opus `flutter-code-reviewer`: ✅ must-fix 1 + should-fix 1 모두 반영, nit 4건 범위 외 이관

### 머지 / 배포
- feature 커밋: `69b77cf` (BLoC PR8: AddArticleCubit 도입 — 수동 추가 시트 상태 이동)
- docs 커밋: `6849649` (docs(bloc): PR 8 완료 핸드오프 노트 + SESSION_LOG + README 트래커 업데이트)
- **develop 머지**: `14910bb` (`--no-ff` Merge feature/bloc-08-add-article)
- **origin push 완료**: `feature/bloc-08-add-article` 최초 push, `develop` 9c897bf..14910bb
- 브랜치 보존: `feature/bloc-08-add-article`

### 다음 세션 즉시 시작 프롬프트 (PR 9 — HomeBloc)

```
doc/bloc-migration/pr-09-home.md 정독하고 PR 9(HomeBloc) 작업 시작.
이전 세션(PR 8) 결과는 SESSION_LOG.md 최상단. 아래 컨벤션 준수.

## PR 1~8 확립 컨벤션

1. bloc_test 미도입: `flutter_test` + `Cubit.stream.listen` + `expectLater` + `await Future<void>.delayed(Duration.zero)`
2. Hive 격리 path: `setUpAll`에서 `.dart_tool/test_hive_<name>`, 어댑터 등록, setUp clear + skipSync=true, tearDownAll deleteFromDisk
3. 전역 BlocProvider = ThemeCubit + AuthCubit만. HomeBloc은 화면 로컬
4. TextEditingController/CardSwiperController 등 위젯 생명주기 결합 컨트롤러는 StatefulWidget 로컬 유지(SSOT)
5. Bloc의 Event + State는 Equatable, state는 copyWith 필수
6. 다이얼로그/시트 호출 **전** `final bloc = context.read<HomeBloc>()` 캡처
7. articlesChangedNotifier 중복 발사 금지: DB 서비스 내부 발사 경로 확인 후 Bloc에서 추가 발사 X
8. 브랜치 워크플로: develop ↔ origin/develop 동기화 → `feature/bloc-09-home` 분기 → feature 커밋 → docs 커밋 → `--no-ff` develop 머지 → 사용자 승인 후 push
9. 서브에이전트 병렬 dispatch: haiku(단순 파일) / sonnet(로직) / opus(flutter-code-reviewer 최종)
10. 시뮬레이터 스모크: 사용자 요청 시만

## PR 9 시작 시 즉시 할 일

1. `git status` + develop/origin/develop 동기화
2. `doc/bloc-migration/pr-09-home.md` 정독
3. `lib/screens/home_screen.dart` 전체 Read (LOC 확인)
4. `git checkout -b feature/bloc-09-home`
5. `flutter analyze` 기준선
6. 영향 범위 한 줄 요약 + 사용자 승인 후 시작

## PR 9 알려진 주의사항

- **Bloc 사용 (Cubit 아님)**: swipe 이벤트(`markAsRead`/`skip`/`undo`) 이벤트 기반
- **CardSwiperController**: 덱 재생성 시 `addPostFrameCallback`에서 이전 컨트롤러 일괄 dispose. 이중 dispose 방지 `try-catch` 유지
- **SwipeAdCard 8-간격 삽입**: itemBuilder 책임(Bloc state에 들어가지 않음)
- **HomeOverlayGuide 첫 실행 플래그**: DatabaseService 경유 그대로 유지
- **articlesChangedNotifier 중복 발사 주의**: DB 서비스가 이미 발사하는 경우 Bloc에서 추가 발사 금지
```

---

## 2026-04-21 PR 07 — BookmarkedArticlesScreen + LabelDetailScreen (Cubit 재사용)

**세션 결과**: 🟢 완료 (develop 머지 + push 완료)

**브랜치**: `feature/bloc-07-bookmarked-label` (feature 커밋: `ea6de85`, docs 커밋: `e61d857`, `6f897ed`, 머지 커밋: `0595316`)
**선행 커밋**: `a46d96e` (docs(bloc): PR 6 실제 구현 반영 + PR 7 사전 정리 — develop 직접 반영)

### 계획대로 된 점
- `BookmarkedArticlesScreen` / `LabelDetailScreen` 모두 `ArticleListCubit` + 공통 위젯 재사용으로 전환.
- 공통 위젯 2종 신규 분리:
  - `lib/widgets/memo_sheet.dart` — `MemoSheet.show()` 정적 헬퍼, TextEditingController 라이프사이클 안전.
  - `lib/widgets/article_actions_sheet.dart` — `ArticleActionsSheet.show()` 정적 헬퍼, 롱프레스 액션 5종 + 삭제 confirm + MemoSheet 연계.
- 3개 화면(All/Bookmarked/LabelDetail) 모두 공통 위젯 사용. `AllArticlesScreen`도 PR 7 리팩터 부수 효과로 shared widgets 채택.
- LabelDetail 고유 요소 유지: AppBar CircleAvatar(라벨명 첫 글자) / TabBar indicator/label color / empty 아이콘 labelColor.
- 통계 헤더는 state 파생 계산으로 전환 (`state.total/readCount/unreadCount`) — `DatabaseService.getLabelStats()` 직접 호출 제거.
- Tab listener `setState(() {})` 포함 — PR 6 교훈 그대로.
- `flutter analyze` No issues, `flutter test test/blocs/` 49 PASS.

### 계획과 다르게 된 점
- **PR 7 문서의 "테스트 추가" 항목 불필요**: Bookmarked/ByLabel 테스트는 PR 6에서 이미 추가됨(`test/blocs/article_list_cubit_test.dart` L125-153). 기존 49 PASS 유지.
- **`_showArticleActions`의 labelColor 파라미터 드롭**: 기존 LabelDetail 코드는 labelColor를 전달받았지만 body에서 미사용(데드 코드). 공통 `ArticleActionsSheet`는 파라미터 불요.
- **`ArticleListItem`에 labelColor 미추가**: 디자인 일관성 위해 item 내부 뱃지 색은 secondary 유지. 라벨색은 AppBar/TabBar/empty 아이콘만 적용.
- **`ArticleActionsSheet.rootContext` 주입**: 삭제 confirm / MemoSheet 진입은 시트 pop 이후 BuildContext 필요 → 호출 측 context를 `rootContext`로 명시 전달. 내부 _SheetBody context는 pop 후 deactivated.

### 새로 발견한 이슈 / TODO
- `selectedKeys: List<dynamic>` → `List<int>`로 좁히기 검토 (Hive key는 int).
- `_confirmBulkDelete` 3화면 중복 — `bulk_delete_dialog.dart` 추출 가능 (우선순위 낮음).
- `adInterval = 8` 매직 넘버 — PR 11 cleanup에서 AdService 인접 상수로 이동.

### 참고한 링크
- PR 6 선례: `lib/screens/all_articles_screen.dart`, `lib/blocs/article_list/`
- flutter_bloc BlocProvider scoping: https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider

### 다음 세션 유의사항 (PR 8 — AddArticleCubit)
- **AddArticleCubit은 공유/수동 저장 플로우**. 인라인 form 상태(`TextEditingController`, 로딩 flag)를 Cubit state로 승격.
- 상태: `isLoading` / `errorMessage`. `clearError()` 공개 메서드.
- `ScrapingService` 호출을 Cubit 내부에서 직접. 실패 시 errorMessage state, SnackBar는 BlocListener + listenWhen 가드.
- **공통 위젯 재사용 현황**: `ArticleListCubit` / `ArticleListView` / `BulkActionBar` / `ArticleActionsSheet` / `MemoSheet` 모두 PR 6~7에서 분리 완료. PR 8은 추가 위젯 분리 없음.
- 컨벤션 불변 (PR 1~7): bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 서브에이전트 병렬 dispatch / 시뮬레이터 스모크는 사용자 요청 시만.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/`: ✅ 49 PASS
- 실기기 스모크: ⚪ 미수행

### LOC 감소 결과
- `bookmarked_articles_screen.dart`: **664 → 228 LOC** (-65.7%)
- `label_detail_screen.dart`: **685 → 251 LOC** (-63.4%)
- `all_articles_screen.dart`: 506 → 230 LOC (-54.5%, 부수 효과)
- 신규: `memo_sheet.dart` 162 + `article_actions_sheet.dart` 160 = 322 LOC
- **순 감소**: 1855 → 1031 LOC (**-824, -44.4%**)

### 완료 못한 항목 (스모크 테스트는 모든 PR 정리 후 진행 예정)
- **실기기/시뮬레이터 스모크 미실행**: 사용자 방침 — 모든 PR plan 정리 후 일괄 진행. Bookmarked/LabelDetail 핵심 플로우(다중 선택 / 일괄 액션 / 메모 / 라벨 pop / 탭 카운트 갱신) 실기기 검증 필요.
- **리뷰어 지적 nit 1 (후속 이관)**: LabelDetail 아이템 뱃지(check_circle/bookmark) 색이 labelColor → secondary로 회귀. `ArticleListItem`에 `Color? accentColor` 옵션 추가로 1-2줄 개선 가능. 디자인 의도라면 수용.
- **리뷰어 지적 nit 2 (후속 이관)**: `_confirmBulkDelete` 3화면 중복 30줄. `showBulkDeleteConfirm(context, cubit)` 헬퍼 추출 또는 `BulkActionBar.onDelete` 시그니처 승격. PR 8 이후 추가 화면 나올 때 재검토.
- **`bulkDelete` for-await 순차 (PR 6 TODO)**: 100개 삭제 시 DB 100회 + Firestore 동기화 순차. `DatabaseService.bulkDelete` 도입으로 batch + 단일 sync trigger 개선 필요. 후속 PR 대상.

### 머지 / 배포
- feature 커밋: `ea6de85` (BLoC PR7: Bookmarked/LabelDetail 화면 ArticleListCubit 재사용)
- docs 커밋: `e61d857` (docs(bloc): PR 7 완료 핸드오프 노트 + SESSION_LOG + README 트래커 업데이트)
- docs 보강 커밋: `6f897ed` (docs(bloc): PR 7 세션 로그 보강 + SESSION_STARTER 파일 경로 캐시 갱신)
- **develop 머지**: `0595316` (`--no-ff` Merge feature/bloc-07-bookmarked-label)
- **origin push 완료**: `feature/bloc-07-bookmarked-label` 최초 push, `develop` b92010f..0595316
- opus `flutter-code-reviewer` 최종 리뷰: ✅ LGTM, must-fix 0, nit 2건 (후속 이관)
- 브랜치 보존: `feature/bloc-07-bookmarked-label`

### 다음 세션 즉시 시작 프롬프트 (PR 8 — AddArticleCubit)

다음 세션 시작 시 아래 프롬프트를 그대로 복사해 사용:

````
doc/bloc-migration/pr-08-add-article.md를 정독하고 PR 8(AddArticleCubit) 작업을 시작해줘.
이전 세션(PR 7) 결과는 SESSION_LOG.md 최상단에 있어. 아래 컨벤션을 반드시 따를 것.

## PR 1~7에서 확립된 컨벤션

1. **bloc_test 미도입**: Cubit 단위 테스트는 `flutter_test` + `Cubit.stream.listen` + `expectLater` + `await Future<void>.delayed(Duration.zero)`
2. **Hive 테스트 격리 path**: `setUpAll`에서 `Hive.init('.dart_tool/test_hive_<name>')` + 필요 box `openBox` + 어댑터 등록, `setUp`에서 `clear` + `DatabaseService.skipSync = true`, `tearDownAll`에서 `deleteFromDisk`
3. **전역 vs 화면 로컬 BlocProvider**: 전역 = ThemeCubit + AuthCubit. **AddArticleCubit은 화면 로컬** `BlocProvider` (AddArticleSheet 또는 수동 저장 화면 로컬)
4. **StatefulWidget + BlocProvider 조건부 분리**: 로컬 상태(TextEditingController 등) 있으면 `_XxxBody(StatefulWidget)` 분리, 없으면 StatelessWidget 단일
5. **`articlesChangedNotifier` 브릿지**: Cubit의 성공 저장 후 `articlesChangedNotifier.value++` 트리거 (기존 `DatabaseService.saveArticle`이 이미 처리 중인지 확인). `ShareService.processAndSave()` 내부와 중복 발사 유의
6. **`BlocListener` 내 외부 `emit` 불가**: Cubit에 `void clearError()` 공개 메서드 필수
7. **`listenWhen` 엄격 가드**: `prev.errorMessage != curr.errorMessage && curr.errorMessage != null` — 동일 에러 재진입 시 SnackBar 중복 방지
8. **다이얼로그/시트에서 cubit 사용 시 `showDialog`/`showModalBottomSheet` 호출 **전** `final cubit = context.read<AddArticleCubit>()` 캡처**
9. **공통 위젯 재사용 현황 (PR 6~7)**: `ArticleListCubit` / `ArticleListView` / `BulkActionBar` / `ArticleActionsSheet` / `MemoSheet` 완료. PR 8 신규 공통 위젯 추출은 불필요(예상).
10. **브랜치 워크플로**: `develop ↔ origin/develop` 동기화 확인 → `feature/bloc-08-add-article` 분기 → feature 푸시 → `--no-ff` develop 머지 → 문서 커밋 → develop 푸시. PR 생성 X. 사용자 승인 후 push
11. **서브에이전트 병렬 dispatch + 모델 정책**: 단순 파일 haiku / 로직 파일 sonnet / 최종 검토만 opus `flutter-code-reviewer`
12. **시뮬레이터 스모크**: 사용자가 요청할 때만 진행
13. **기존 `test/widget_test.dart`는 broken**: PR 11 위임

## PR 8 시작 시 즉시 할 일

1. `git status` + `develop`/`origin/develop` 동기화 확인 (PR 7 머지/push 사전 진행 여부 확인)
2. `doc/bloc-migration/pr-08-add-article.md` 정독
3. `lib/widgets/add_article_sheet.dart` 전체 Read + 진입점 확인 (`MainScreen._checkPendingShares` / 설정화면 수동 추가)
4. `lib/services/scraping_service.dart` 시그니처 확인 (`scrape(url)` 반환 타입, 실패 케이스)
5. `lib/services/database_service.dart`의 `saveArticle` / `articlesChangedNotifier` 트리거 경로 재확인
6. `git checkout -b feature/bloc-08-add-article`
7. `flutter analyze` 기준선 확인
8. 작업 계획 한 줄 요약 + 영향 범위 보고 후 시작

## PR 8 알려진 주의사항

- **상태**: `url` (입력) / `isScraping` / `scrapedArticle: Article?` / `selectedLabels: List<String>` / `errorMessage` / `isSaving`. 정확 필드는 pr-08 정독 후 결정.
- **메서드(예상)**: `urlChanged(String)` / `scrape()` / `toggleLabel(String)` / `save()` / `clearError()` / `reset()`.
- **URL 검증**: `Uri.tryParse(url)?.hasAbsolutePath` — 빈값/상대경로 거절. 검증 실패 시 errorMessage 즉시 emit.
- **스크래핑 실패 fallback**: `ScrapingService.scrape()` 예외 시에도 URL + fallback title로 저장 허용 여부 기존 UX 확인.
- **`TextEditingController`**: 화면 StatefulWidget 로컬. Cubit에는 `url` state만. 중복 단일 진실원천(SSOT) 주의 — 입력 변경을 cubit에 밀어넣을지 최종 save 시점에만 넘길지 결정.
- **ShareLabelSheet / add_article_sheet 공용화 가능성**: 두 진입점 UX가 유사하므로 공통 위젯 추출 검토.
- **articlesChangedNotifier 발사**: `DatabaseService.saveArticle` 내부에서 이미 발사하면 Cubit 내 추가 발사 금지(레이스).
- **테스트**: state copyWith + Hive 격리 + `scrape()` happy path (http mock 불필요 시) + `save()` + `clearError()`.
````

## 2026-04-21 PR 06 — ArticleListCubit + AllArticlesScreen

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-06-article-list` (머지 커밋: develop HEAD)

### 계획대로 된 점
- `lib/blocs/article_list/` 3파일(source/state/cubit) 신규. sealed `ArticleListSource`에 Equatable 상속 → 파일 경계 across 패턴매칭.
- `ArticleListState.generation` 카운터 도입 — Hive in-place 변경 시 Equatable deep-eq 우회(핵심 발견).
- `lib/widgets/article_list_item.dart`, `article_list_view.dart`, `bulk_action_bar.dart` 공통 위젯 분리 (PR 7 재사용 기반).
- `AllArticlesScreen` → StatelessWidget + BlocProvider, `_AllArticlesBody` StatefulWidget(TabController vsync 유지).
- cubit 캡처 후 showModalBottomSheet 패턴 일관 적용.
- 22개 테스트 all pass (flutter_test + stream.listen + `await Future.delayed(Duration.zero)` 패턴).
- Opus 최종 리뷰 → C1/I1 두 이슈 수정 완료.

### 계획과 다르게 된 점
- **`ArticleListSource` private 서브클래스 불가**: 플랜 PR-06 문서의 `_All` 등 private 서브클래스는 별도 파일에서 패턴매칭 불가 → public `ArticleListSourceAll/Bookmarked/ByLabel`로 변경.
- **`generation` 카운터 필요**: Equatable + Hive in-place 변경의 조합으로 article 필드 변경(isRead, isBookmarked 등) 후 emit이 스킵되는 현상 → `generation` 카운터로 해결.
- **`_reloadAndClearSelection()` helper**: 일괄 액션마다 reload+clear를 두 번 emit하면 중간 stale 상태가 발생 → 단일 emit helper로 통합.
- **`bloc_test` 미사용**: async broadcast stream 특성으로 `await Future.delayed(Duration.zero)` 필요 → library_cubit_test 동일 패턴 채택.
- **`_MemoSheet` StatefulWidget 추출**: Opus 리뷰 지적(TextEditingController 누수) → StatefulWidget + dispose()로 해결.
- **TabController 리스너에 `setState` 추가**: `clearSelection()` Equatable 스킵 시 탭 헤더 stale 방지.
- **`_fetch()` helper 추출**: load()와 _reloadAndClearSelection()의 switch 중복 제거.

### 새로 발견한 이슈 / TODO
- **Opus nit 보류(PR 7 전 처리 권장)**: 액션 시트 3종 모달을 `lib/widgets/article_actions_sheet.dart`로 추출하면 PR 7에서 복붙 없이 재사용 가능.
- **`adInterval = 8` 상수**: `ArticleListView`에서 magic number 사용 중. `AdService` 인접 상수로 승격 검토.
- **`bulkDelete` 순차 await**: 아이템 수에 비례 지연. `Future.wait` 병렬화 검토(Firestore rate-limit 고려).
- **`selectedKeys: List<dynamic>`**: Hive key는 int이므로 `List<int>`로 좁히기 검토(PR 7 시작 전).
- **`articlesChangedNotifier` 연속 발사 레이스**: 짧은 간격 다중 트리거 시 emit 순서 미보장 — 실무 영향 낮으나 테스트 주석 명시 검토.

### 참고한 링크
- PR 5 선례: `lib/blocs/label_management/`, `test/blocs/label_management_cubit_test.dart`
- PR 4 선례: `lib/blocs/library/`, `test/blocs/library_cubit_test.dart`
- flutter_bloc BlocBuilder: https://bloclibrary.dev/flutter-bloc-concepts/#blocbuilder

### 다음 세션 유의사항
- **PR 7 재사용 기반 준비 완료**: `ArticleListCubit(const ArticleListSourceBookmarked())` / `ArticleListCubit(ArticleListSourceByLabel(label.name))`로 소스만 바꿔 BookmarkedArticlesScreen / LabelDetailScreen에 그대로 적용.
- **공통 위젯 위치**: `lib/widgets/article_list_item.dart`, `article_list_view.dart`, `bulk_action_bar.dart` — import 경로 확인.
- **LabelDetail labelColor**: `ArticleListItem`에 labelColor 파라미터 없음. PR 7에서 LabelDetail에 맞게 확장 또는 별도 아이템 위젯 사용.
- **Opus nit 상태**: `article_actions_sheet.dart` 추출은 PR 7 시작 시 결정할 것.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/`: ✅ 49 passed (22개 신규)
- 실기기 스모크: ⚠️ (미수행, 다음 세션에서 기회 시 확인)

## 2026-04-20 PR 05 — LabelManagementCubit

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-05-label-mgmt` (feature 커밋: `65ab02f`, 머지 커밋: `1ece09e`)

### 계획대로 된 점
- `lib/blocs/label_management/label_management_state.dart` + `label_management_cubit.dart` 신규 (플랜 3~4절 스니펫과 거의 동일).
- `LabelManagementScreen` StatefulWidget → StatelessWidget + `BlocProvider` + `_LabelManagementBody(StatelessWidget)` 교체.
- 다이얼로그 내부 `StatefulBuilder` 3종(notification / labelEdit / colorPicker) 그대로 유지 — 요일/시간/스위치/색상 로컬 상태 보존.
- 저장 경계(`createLabel` / `updateLabel` / `deleteLabel` / `updateNotification`)만 Cubit으로 이동. `NotificationService.cancelForLabel`까지 `deleteLabel` 내부로 흡수.
- `clearError()` public 메서드 + `BlocConsumer`의 `listenWhen` 가드 + listener 내 SnackBar 후 즉시 `clearError`.
- 유닛 테스트 3 PASS: `copyWith(clearError: true)` / `copyWith` 보존 / 초기 기본값.
- **사용자 요청 서브에이전트 병렬 dispatch**: Haiku 1개(state + test) + Sonnet 2개(cubit / screen) 동시 실행 → 약 85초에 완료. 최종 Opus 리뷰 LGTM.

### 계획과 다르게 된 점
- **`Map<String, LabelStats>` → `Map<String, ({int total, int read})>`**: 플랜 3절 오기재. PR 4 교훈을 본 PR에서 최초 적용 — 별도 클래스 없이 Dart record 직결.
- **`updateLabelNotification` 파라미터명**: 플랜 4절의 `notificationEnabled` / `notificationDays` / `notificationTime`은 오기재 → 실제 시그니처 `enabled:` / `days:` / `time:`로 맞춤.
- **양쪽 notifier 구독**: 플랜은 `labelsChangedNotifier`만 언급했으나, 라벨 통계 `getLabelStats`는 아티클 `isRead`에 의존 → `articlesChangedNotifier`도 함께 `addListener(_onChanged)` + `close()`에서 짝 `removeListener`. PR 4와 동일한 양쪽 구독 패턴.
- **`_LabelManagementBody`는 StatelessWidget**: PR 3의 "StatefulWidget 분리" 패턴은 PR 4에서 조건부로 재해석됨. 본 화면은 로컬 상태 0 → StatelessWidget 단일로 충분.
- **다이얼로그 `cubit` 캡처 패턴**: 플랜 5.2의 `ctx.read<LabelManagementCubit>()`는 `showDialog` route가 provider 범위를 이탈하므로 동작 불가. `final cubit = context.read<LabelManagementCubit>();`를 **`showDialog` 호출 전**에 capture해 클로저가 참조. 3개 다이얼로그(`_showNotificationDialog` / `_showLabelDialog` / `_confirmDelete`) 모두 동일.
- **`_showLabelDialog` try/catch 제거**: 기존 inline `ScaffoldMessenger` SnackBar는 Cubit `errorMessage` + `BlocListener`로 일원화. 저장 버튼은 `cubit.state.errorMessage == null` 조건에서만 `Navigator.pop` → 실패 시 다이얼로그는 열린 채 SnackBar 표시, 재시도 가능.
- **`_confirmDelete` stats 파라미터화**: screen에서 `DatabaseService.getLabelStats` 직접 호출 제거. `itemBuilder`에서 `state.labelStats[label.name]!` 캡처 후 `_confirmDelete(context, label, stats)`로 전달. **screen 파일에서 `database_service.dart` / `notification_service.dart` import 완전 제거** 달성.
- **`listenWhen` 엄격 가드**: `prev.errorMessage != curr.errorMessage && curr.errorMessage != null` — 동일 에러 재진입 시 SnackBar 중복 방지. PR 4 대비 강화.
- **서브에이전트 3병렬 + 최종 Opus 리뷰 워크플로 확립**: 단순 파일은 Haiku, 로직 파일은 Sonnet, 검토만 Opus. 3에이전트가 서로 다른 파일을 쓰므로 worktree 격리 불요. 이후 PR에 그대로 재사용 가능.

### 새로 발견한 이슈 / TODO
- **`state.labels` ↔ `state.labelStats` 동기성**: `load()`에서 동시 emit이므로 현재는 안전. 부분 emit 메서드(예: `copyWith(labels: ...)`만) 추가 시 `itemBuilder`의 `state.labelStats[label.name]!` 강제 언랩에서 crash 가능 → 메서드 추가 규약: 두 필드는 항상 함께 emit.
- **`_showNotificationDialog` 타임피커 취소 거동**: `showModalBottomSheet`를 스와이프로 닫아도 `onDateTimeChanged`의 마지막 `tempTime`이 반영됨. 기존 동일(회귀 아님). 명시적 취소 UX 필요 시 confirmed flag.
- **`updateNotification` 권한 거부 시 상태 불일치**: DB `enabled: true` 저장되지만 실제 예약 skip. 후속에서 권한 거부 시 `enabled` 롤백 또는 안내 추가 검토(PR 5 범위 밖).
- **Cubit 통합 테스트 미작성**: copyWith 3종만. 후속에서 여력 시 Hive 격리 path로 `createLabel` / `updateLabel` / `deleteLabel` / `updateNotification` 통합 테스트 추가 가능(필수 아님, 실기기 QA로 커버 중).
- **리뷰 nit 보류**: (a) `createLabel` catch + finally 2회 emit은 `listenWhen` 덕에 UX 영향 없어 유지, (b) `for (final l in labels)` 변수명은 다른 파일의 `AppLocalizations l`와 시각적 충돌(컴파일 영향 없음) — 의도적 보류.
- **`DECISION_LOG.md` / `PROJECT_STATE.md` / `doc/img/` 루트 untracked 유지**: PR 4와 동일 — 다른 스킬 산출물. PR 5 범위 밖.

### 참고한 링크
- flutter_bloc BlocConsumer: https://bloclibrary.dev/flutter-bloc-concepts/#blocconsumer
- Dart records equality: https://dart.dev/language/records#record-types
- PR 4 선례: `lib/blocs/library/`, `test/blocs/library_cubit_test.dart`
- PR 1~4: `lib/blocs/{theme,auth,onboarding,library}/`, `test/blocs/*_test.dart`

### 다음 세션 유의사항
- **PR 6은 중량급**: `ArticleListCubit` 공통 Cubit 도입 + `AllArticlesScreen` 적용. Bookmarked/LabelDetail은 PR 7에서 **동일 Cubit 재사용**.
- **source enum 분기**: `all` / `bookmarked` / `byLabel(name)` — PR 4 README.md 경고("byLabel(name) 이스케이프 문제")를 시작 시 먼저 확인.
- **다중 선택 승격**: `_isSelecting` + `Set<dynamic> _selectedKeys`를 상태로. Hive `dynamic` key 유지 — 타입 동일성 주의.
- **8개마다 `InlineBannerAd`**: itemBuilder 책임. Cubit 상태 관여 없음.
- **`articlesChangedNotifier`만 구독으로 충분**: PR 6의 아티클 리스트는 라벨 목록 자체를 쓰지 않음. (PR 7 LabelDetail은 헤더 색/이름이 필요하면 재검토.)
- **진입점 3개에서 각각 `BlocProvider(create: ... with source)`**: screen-local provider 유지.
- **라벨 통계 자동 갱신은 이미 보장**: PR 4/5의 양쪽 notifier 덕에 아티클 변경 시 Library/LabelManagement가 자동 재로드. PR 6은 이를 활용만.
- **컨벤션 불변**: bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 서브에이전트 병렬 dispatch + 모델 정책(단순 haiku, 로직 sonnet, 최종 리뷰 opus) / 시뮬레이터 스모크 요청 시만.
- **기존 `test/widget_test.dart`**: 여전히 broken(pre-existing). PR 11 위임.

### 검증 결과
- `flutter analyze`: ✅ No issues found (ran in 2.2s)
- `flutter test test/blocs/label_management_cubit_test.dart`: ✅ 3/3 passed
- 실기기 스모크: ⚪ 사용자 요청 시에만 진행 (미수행)
- Opus 최종 리뷰: ✅ LGTM, nit 2건 의도적 보류

### 머지 / 배포
- `develop` 머지(--no-ff): `1ece09e` (`Merge feature/bloc-05-label-mgmt: BLoC PR 5 — LabelManagementCubit 도입`)
- `feature/bloc-05-label-mgmt` → `origin` push 완료
- `develop` → `origin/develop` push: **본 문서 커밋 후 일괄 push 예정**
- `feature/bloc-05-label-mgmt` 브랜치 보존

### 다음 세션 즉시 시작 프롬프트 (PR 6 — ArticleListCubit + AllArticlesScreen)

다음 세션 시작 시 아래 프롬프트를 그대로 복사해 사용:

````
doc/bloc-migration/pr-06-article-list-all.md를 정독하고 PR 6(ArticleListCubit + AllArticlesScreen) 작업을 시작해줘.
이전 세션(PR 5) 결과는 SESSION_LOG.md 최상단에 있어. 아래 컨벤션을 반드시 따를 것.

## PR 1~5에서 확립된 컨벤션

1. **bloc_test 미도입**: Cubit 단위 테스트는 `flutter_test` + `Cubit.stream.listen` + `expectLater`
2. **Hive 테스트 격리 path**: `setUpAll`에서 `Hive.init('.dart_tool/test_hive_<name>')` + 필요 box `openBox` + 어댑터 등록, `setUp`에서 `clear`, `tearDownAll`에서 `deleteFromDisk`
3. **전역 vs 화면 로컬 BlocProvider**: 전역 = ThemeCubit + AuthCubit. **ArticleListCubit은 화면 로컬** `BlocProvider`. 진입점 3개(AllArticles / Bookmarked / LabelDetail)에서 각각 `create: (_) => ArticleListCubit(source: ...)`.
4. **StatefulWidget + 화면 로컬 BlocProvider**: **조건부** 선택지. 로컬 상태 없으면 StatelessWidget 단일로 충분(PR 4/5 선례). AllArticles는 `ScrollController` 또는 `AnimationController` 쓰면 `_XxxBody(StatefulWidget)` 분리 필요 — 시작 시 판단.
5. **`articlesChangedNotifier` 브릿지**: Cubit 생성자 `addListener(_onChanged)` → `_onChanged() => unawaited(load())` → `close()`에서 `removeListener`. PR 6은 **`articlesChangedNotifier`만 구독** 충분(라벨 목록 자체 미사용). PR 7의 LabelDetail 헤더에서 라벨 색/이름 필요 시 그때 `labelsChangedNotifier` 추가.
6. **Navigator.pop 후 명시 `load()`**: Cubit 내부 CRUD 메서드가 이미 `load()`를 부르면 자동 재로드. 외부 이벤트(공유/동기화)로 새 아티클 들어오는 경우는 notifier가 트리거. 아티클 상세 화면은 없으므로(외부 브라우저) 해당 없음.
7. **통계 타입은 Dart 레코드** `({int total, int read})` — PR 5에서 최초 적용.
8. **`BlocListener` 내 외부 `emit` 불가** → Cubit에 `void clearError()` 공개 메서드.
9. **다이얼로그에서 cubit 사용 시 `showDialog` 호출 **전** `final cubit = context.read<XxxCubit>()` 캡처** (PR 5 교훈). BottomSheet도 동일.
10. **CLAUDE.md/플랜 문서의 `themeModeNotifier` / `authStateNotifier` 잔존 언급 무시**: PR 11 위임.
11. **브랜치 워크플로**: `develop ↔ origin/develop` 동기화 확인 → `feature/bloc-06-article-list` 분기 → feature 푸시 → `--no-ff` develop 머지 → 문서 커밋 → develop 푸시. PR 생성 X. 사용자 승인 후 push.
12. **서브에이전트 병렬 dispatch + 모델 정책**: 단순 파일(state/test 템플릿) haiku / 로직 파일(cubit/screen) sonnet / 최종 검토만 opus. 3~4개 에이전트 동시 실행.
13. **시뮬레이터 스모크**: 사용자가 요청할 때만 진행.
14. **기존 `test/widget_test.dart`는 broken**: PR 11 위임.

## PR 6 시작 시 즉시 할 일

1. `git status` + `develop`/`origin/develop` 동기화 확인
2. `doc/bloc-migration/pr-06-article-list-all.md` 정독 + `lib/screens/all_articles_screen.dart` Read
3. `lib/screens/bookmarked_articles_screen.dart` / `label_detail_screen.dart` 비교 Read — 공통점/차이점 파악 (PR 7 재사용 설계)
4. `lib/services/database_service.dart`에서 `getAllArticles` / `getBookmarkedArticles` / `getArticlesByLabel` / `markAsRead` / `markAsUnread` / `bulkMarkRead` / `bulkSetBookmark` / `toggleBookmark` / `updateMemo` / `deleteArticle` / `updateArticleLabels` 시그니처 확인
5. `git checkout -b feature/bloc-06-article-list`
6. `flutter analyze` 기준선 확인
7. 작업 계획 보고 후 승인 시 시작

## PR 6 알려진 주의사항 (pr-06-article-list-all.md 정독 전 참고)

- 상태: `articles` / `source` enum / `isSelecting` / `selectedKeys: Set<dynamic>` / `isLoading` / `isSaving` / `errorMessage`.
- 메서드(예상): `load()` / `toggleSelection(key)` / `clearSelection()` / `markRead(articles)` / `markUnread(articles)` / `bulkMarkRead(articles, isRead)` / `toggleBookmark(article)` / `bulkSetBookmark(articles, bookmark)` / `updateMemo(article, memo)` / `delete(articles)` / `updateLabels(article, labels)` / `clearError()`.
- `source` enum: `all` / `bookmarked` / `byLabel(String name)` — sealed class 또는 enum + 옵션 필드. **PR 4 README 경고: byLabel(name) 이스케이프 문제** 시작 시 확인.
- 다중 선택 UX: 롱프레스로 진입 / 상단바 액션(읽음/안읽음/북마크/삭제) / 뒤로 누르면 해제. 기존 `_isSelecting` + `Set<dynamic>`를 Cubit으로 이동.
- 아티클 행 탭: 외부 브라우저(`url_launcher`). Cubit 상태 변화 없음.
- 8개마다 `InlineBannerAd`: itemBuilder 책임.
- 롱프레스 바텀시트(단일 아이템 액션): `showModalBottomSheet` → 내부에서 cubit capture 후 액션 호출.
- 라벨 편집 바텀시트: `LabelEditSheet` 위젯 → `updateLabels` 호출.
- 메모 다이얼로그: `updateMemo` 호출 (빈 문자열은 null로 변환 로직 DatabaseService에 있음).
- 테스트 최소 범위: state `copyWith` + Hive 격리 `load()` + `toggleSelection` 순수 로직. CRUD 통합은 여력 시.
````

---

## 2026-04-20 PR 04 — LibraryCubit

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-04-library` (feature 커밋: `4e5d1d5`, 머지 커밋: `f4e5f22`)

### 계획대로 된 점
- `lib/blocs/library/library_cubit.dart` + `library_state.dart` 신규 — 플랜 4절 스니펫과 거의 동일.
- `articlesChangedNotifier` + `labelsChangedNotifier` 두 전역 notifier를 Cubit 생성자에서 `addListener(_onChanged)` → `close()`에서 `removeListener`. **README L108 브릿지 템플릿 최초 적용**.
- `LibraryScreen`을 StatefulWidget → StatelessWidget + `BlocProvider(LibraryCubit)` → `_LibraryBody(StatelessWidget)` + `BlocBuilder`로 교체.
- Navigator.push 후 `context.read<LibraryCubit>().load()` 명시 호출 (스펙 5.3).
- 카드 4종(`_OverallStatsCard` / `_AllCard` / `_BookmarkCard` / `_LabelCard`)을 별도 StatelessWidget으로 분리.
- 유닛 테스트 7 PASS.

### 계획과 다르게 된 점
- **`LibraryState`가 `OverallStats` / `BookmarkStats` / `LabelStats` 값 클래스 미사용**: `DatabaseService`의 실제 반환 타입은 Dart 레코드 `({int total, int read})`. 레코드는 구조적 `==`를 가져 Equatable의 Map 비교에서도 정상 동작 → 래퍼 클래스 / `DeepCollectionEquality` 도입 불필요. 플랜 3절의 "값 클래스" 언급은 무시. **PR 5 플랜의 `Map<String, LabelStats>`도 동일한 오기재이므로 레코드로 교체 필요**.
- **`_LibraryBody(StatefulWidget)` 분리 패턴 미적용**: PR 3에서 확립한 패턴은 "StatefulWidget + provider-scoped context 동시 필요 시"에만 적용. LibraryScreen은 로컬 상태(PageController 등)가 전혀 없어 StatelessWidget으로 충분. **컨벤션 4 해석 명확화**: 해당 패턴은 기본 선택지가 아니라 조건부 선택지.
- **플랜의 `bloc_test` 스니펫 → `flutter_test` + `Cubit.stream` 패턴으로 교체**: PR 1~3 컨벤션 일관성.
- **유닛 테스트 범위 확장**: 플랜 7절은 "copyWith만이라도" 허용했지만, Hive 격리 path(`.dart_tool/test_hive_library_cubit`) + Article/Platform/Label 어댑터 등록으로 통합 테스트 7개 작성 (생성자 동기 load / 빈 DB / 두 notifier trigger / close 후 무시 / copyWith / Equatable).
- **리뷰 nit 2건 반영**: `_LabelCard`만 `AppLocalizations.of(context)!`를 내부에서 얻던 비대칭 → `AppLocalizations l` 파라미터로 통일. `_onChanged`는 `unawaited(load())`로 Future discard 의도 명시.

### 새로 발견한 이슈 / TODO
- **(중요) PR 3 핸드오프 노트 오류 정정**: PR 3 핸드오프에 "Navigator.push 후 복귀 시 `setState({})` 호출 → Cubit 전환 후에는 notifier 트리거로 자동 재로드되므로 명시 setState 제거 가능"이라 기재되었으나 **틀림**. `articlesChangedNotifier.value++`는 `share_service.dart:68`(새 공유 URL 수신)과 `sync_service.dart:276`(Firestore 스냅샷 머지)에서만 발동되고, 로컬 DB ops(`markAsRead`, `toggleBookmark`, `deleteArticle`, `updateMemo` 등)는 notifier를 트리거하지 않는다. 따라서 Navigator.push → pop 후 명시 `load()` 호출이 필수. **PR 5~7 동일 패턴 화면 작업 시 본 교훈 준수**.
- **`load()`의 동기 실행 특성**: `DatabaseService` 통계 API는 모두 동기(Hive in-memory read). `load()` 내부에 `await`가 없어 `async` 함수지만 본문이 동기 완료 → 생성자 반환 시점에 이미 `isLoading=false`. 테스트에서 `stream.firstWhere`로 대기하면 타임아웃되므로, 초기 상태 검증은 생성자 직후 `state`를 직접 읽고, notifier trigger 후 emit은 `stream.listen` 구독 뒤 `Future<void>.delayed(Duration.zero)` 패턴 사용.
- **`LibraryCubit`이 `main.dart`를 import**: notifier가 `main.dart` 최상위에 정의되어 있어 `show articlesChangedNotifier, labelsChangedNotifier`. PR 11 cleanup의 notifier 제거 작업은 이 브릿지 제거가 첫 단계.
- **`DECISION_LOG.md` / `PROJECT_STATE.md` (루트)**: 이번 세션 도중 다른 스킬이 생성한 파일로 파악됨. untracked 상태로 방치. PR 4 범위 밖.

### 참고한 링크
- flutter_bloc BlocProvider scoping: https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider
- Dart records equality: https://dart.dev/language/records#record-types
- Equatable Map comparison: https://pub.dev/packages/equatable
- PR 1~3 선례: `lib/blocs/{theme,auth,onboarding}/`, `test/blocs/*_test.dart`

### 다음 세션 유의사항
- **PR 5 플랜 오기재 수정 필요**: `Map<String, LabelStats>` → `Map<String, ({int total, int read})>`. state/cubit 모두 해당.
- **`DatabaseService.updateLabelNotification` 시그니처 먼저 Read**: PR 5 플랜에 "named param 순서/이름 확인 필수" 명기됨.
- **`DatabaseService.deleteLabel` 내부 동작 확인**: 아티클 `topicLabels`에서 자동 제거되는지.
- **`clearError()` 공개 메서드 필수**: `BlocListener`에서 외부 `emit` 호출 불가. `void clearError() => emit(state.copyWith(clearError: true));` 추가.
- **다이얼로그 내부 `StatefulBuilder` 유지**: 요일/시간/스위치는 다이얼로그 수명 로컬 상태. Cubit은 저장 시점만 관여.
- **Navigator.pop 후 명시 `load()` 관행 유지**: 본 PR 4 교훈. notifier를 쏘지 않는 CRUD는 명시 reload 필요. (PR 5는 CRUD 메서드 내부에서 `load()`를 이미 호출하므로 추가 액션 보통 불필요.)
- **컨벤션 불변**: bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 서브에이전트 모델 정책(단순 haiku, 분석 sonnet, 최종 리뷰만 opus) / 시뮬레이터 스모크는 사용자 요청 시만.
- **기존 `test/widget_test.dart`**: 여전히 broken(pre-existing). PR 11 위임.

### 검증 결과
- `flutter analyze`: ✅ No issues found
- `flutter test test/blocs/`: ✅ 24/24 passed (theme 3 + auth_state 10 + onboarding 4 + library 7)
- 실기기 스모크: ⚪ 사용자 요청 시에만 진행 (미수행)
- `flutter-code-reviewer`(opus): LGTM, nit 2건 반영 완료

### 머지 / 배포
- `develop` 머지(--no-ff): `f4e5f22` (`Merge feature/bloc-04-library: BLoC PR 4 — LibraryCubit 도입`)
- `origin/develop` push: **문서 커밋 후 일괄 push 예정**
- `feature/bloc-04-library` 브랜치 보존

### 다음 세션 즉시 시작 프롬프트 (PR 5 — LabelManagementCubit)

다음 세션 시작 시 아래 프롬프트를 그대로 복사해 사용:

````
doc/bloc-migration/pr-05-label-management.md를 정독하고 PR 5(LabelManagementCubit) 작업을 시작해줘.
이전 세션(PR 4) 결과는 SESSION_LOG.md 최상단에 있어. 아래 컨벤션을 반드시 따를 것.

## PR 1~4에서 확립된 컨벤션

1. **bloc_test 미도입**: cubit 단위 테스트는 `flutter_test` + `Cubit.stream.listen` + `expectLater`
2. **테스트 Hive 격리 path**: `setUpAll`에서 `Hive.init('.dart_tool/test_hive_<name>')` + 필요 box `openBox` + 어댑터 등록 + `setUp`에서 `clear` + `tearDownAll`에서 `deleteFromDisk`
3. **전역 vs 화면 로컬 BlocProvider** (README L104): 전역 = ThemeCubit + AuthCubit. **LabelManagementCubit은 화면 로컬** `BlocProvider`.
4. **StatefulWidget + 화면 로컬 BlocProvider 동시 필요 시 `_XxxBody(StatefulWidget)` 분리 패턴**: **조건부 선택지**(PR 4 교훈). 로컬 상태 없으면 StatelessWidget 단일로 충분.
5. **`articlesChangedNotifier` / `labelsChangedNotifier` 브릿지**: 생성자 `addListener(_onChanged)` → `_onChanged() => unawaited(load())` → `close()`에서 `removeListener`. PR 11까지 브릿지 유지.
6. **Navigator.pop 후 명시 `load()` 필수** (PR 4 교훈): notifier는 `share_service`/`sync_service`에서만 트리거되므로 로컬 DB ops 후에는 자동 재로드 안 됨. 단, Cubit 내부 CRUD 메서드가 이미 `load()`를 부르면 추가 호출 불필요.
7. **통계 타입은 Dart 레코드** `({int total, int read})` (PR 4 확인): `OverallStats`/`BookmarkStats`/`LabelStats` 같은 클래스는 DatabaseService에 존재하지 않음. PR 5 플랜의 `Map<String, LabelStats>`는 `Map<String, ({int total, int read})>`로 교체.
8. **`BlocListener` 내부 외부 `emit` 불가**: Cubit에 `void clearError() => emit(state.copyWith(clearError: true));` 공개 메서드 추가 필수.
9. **CLAUDE.md/플랜 문서의 잔존 언급 무시**: `themeModeNotifier`/`authStateNotifier` — PR 11 cleanup 위임 확정.
10. **브랜치 워크플로**: `develop ↔ origin/develop` 동기화 확인 후 `feature/bloc-05-label-mgmt` 분기 → `--no-ff` 머지 + push (PR 생성 X, 사용자 승인 후 push)
11. **서브에이전트 모델**: 단순 haiku / 분석 sonnet / 최종 리뷰만 opus `flutter-code-reviewer`
12. **시뮬레이터 스모크**: 사용자가 요청할 때만 진행
13. **기존 `test/widget_test.dart`는 broken**: PR 11 위임

## PR 5 시작 시 즉시 할 일

1. `git status` + `develop`/`origin/develop` 동기화 확인
2. `doc/bloc-migration/pr-05-label-management.md` 정독 + `lib/screens/label_management_screen.dart`(514 LOC) Read
3. `lib/services/database_service.dart`에서 `updateLabelNotification` / `deleteLabel` / `updateLabel` 시그니처 확인 (특히 named 파라미터)
4. `lib/services/notification_service.dart`에서 `requestPermission` / `scheduleForLabel` / `cancelForLabel` 확인
5. `git checkout -b feature/bloc-05-label-mgmt`
6. `flutter analyze` 기준선 확인
7. 작업 계획 한 줄 요약 + 영향 범위 보고 후 시작

## PR 5 알려진 주의사항 (pr-05-label-management.md 정독 전 참고)

- 상태: `labels` / `labelStats: Map<String, ({int total, int read})>` (플랜의 `LabelStats`는 레코드로 교체) / `isLoading` / `isSaving` / `errorMessage`.
- 메서드: `load()` / `createLabel(name, color)` / `updateLabel(label, {newName, newColor})` / `deleteLabel(label)` / `updateNotification(label, {enabled, days, time})` / `clearError()`.
- **`labelsChangedNotifier`만 구독**(아티클 통계도 보지만 라벨 변경 시만 재로드). 필요 시 `articlesChangedNotifier`도 추가 검토.
- 다이얼로그 내부 `StatefulBuilder` 유지 (요일/시간/스위치 로컬 상태). 저장 버튼에서 `context.read<LabelManagementCubit>()` 호출.
- 에러 메시지는 `errorMessage` 상태로 승격 + `BlocListener` SnackBar + `clearError()` 호출.
- 라벨 삭제 시 `NotificationService.cancelForLabel(label)` 먼저 호출, 그 다음 `DatabaseService.deleteLabel(label)`.
- 알림 토글 ON: `requestPermission` → 허가 시 `scheduleForLabel`. OFF: `cancelForLabel`.
- `DatabaseService.deleteLabel` 내부에서 아티클 `topicLabels`에서 자동 제거되는지 사전 확인 필요.
- 테스트 최소 범위: state `copyWith(clearError: true)` 등 순수 유닛. Cubit 통합 테스트는 여력 있을 때 (권장).
````

---

**세션 결과**: 🟢 완료

**브랜치**: `feature/bloc-03-onboarding` (feature 커밋: `dbf9028`, 머지 커밋: `71acc3c`)

### 계획대로 된 점
- `lib/blocs/onboarding/onboarding_cubit.dart` 신규 — `Cubit<int>` 패턴(state 클래스 생략), `setPage`(동일값 가드) + `complete()`
- `OnboardingScreen._currentPage` 제거, `setOnboardingComplete()` 호출을 Cubit의 `complete()`로 이동
- 화면 로컬 `BlocProvider`(README L104) 준수
- `PageController`는 위젯 local state로 유지
- 유닛 테스트 4 PASS (생성자, setPage 변화, 동일값 skip, complete → DB persist)

### 계획과 다르게 된 점
- **StatefulWidget → StatelessWidget(BlocProvider) + `_OnboardingBody(StatefulWidget)` 분리**: provider 하위에서 `context.read`를 쓰면서 PageController를 로컬로 유지하려면 분리가 필요. 이 패턴은 PR 4~ 이후 동일 상황에서 그대로 재사용 가능.
- **플랜의 `bloc_test` 스니펫 → `flutter_test` + `Cubit.stream.listen`으로 교체**: PR 1~2 컨벤션 일관성.
- **`complete()` 테스트 작성**: Hive `.dart_tool/test_hive_onboarding_cubit` 격리로 `DatabaseService.hasSeenOnboarding` 토글까지 검증(플랜은 "없으면 skip" 허용 범위).
- **`_onNext/_onSkip/_onComplete`가 `async Future<void>`로 전환**: `onPressed`/`GestureDetector`에서 fire-and-forget. 기존도 동일 패턴이었고 `_onComplete` 내부 `if (!mounted) return;` 가드로 안전.

### 새로 발견한 이슈 / TODO
- `onboarding_screen.dart`의 `SizedBox(height: 20)` 매직 넘버는 기존 코드 유지된 것이며 PR 범위 밖. 레이아웃 정리 시 `Spacing` 토큰 적용 고려.
- OnboardingCubit은 `articlesChangedNotifier`/`labelsChangedNotifier` 브릿지 해당 없음(순수 페이지 인덱스).

### 참고한 링크
- flutter_bloc BlocProvider scoping: https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider
- PR 1~2 선례: `lib/blocs/theme/theme_cubit.dart`, `test/blocs/theme_cubit_test.dart`

### 다음 세션 유의사항
- **PR 4(LibraryCubit)**: `articlesChangedNotifier`/`labelsChangedNotifier` 브릿지 패턴을 처음 적용. README L108 템플릿 숙지 필수.
- **StatefulWidget + 화면 로컬 BlocProvider 동시 필요 시**: PR 3에서 확립한 `_XxxBody(StatefulWidget)` 분리 패턴을 기본 선택지로.
- **Cubit 유닛 테스트 컨벤션 불변**: `flutter_test` + `Cubit.stream.listen` + `expectLater`. `bloc_test` 미도입 유지. 플랜 문서의 스니펫은 무시.
- **Hive 테스트 격리 path 컨벤션 불변**: `.dart_tool/test_hive_<name>` + `setUpAll(openBox)` + `setUp(clear)` + `tearDownAll(deleteFromDisk)`.
- **기존 `test/widget_test.dart`**: 여전히 broken(pre-existing). PR 11 위임.

### 검증 결과
- `flutter analyze`: ✅ No issues found
- `flutter test test/blocs/`: ✅ 17/17 passed (theme 3 + auth_state 10 + onboarding 4)
- 실기기 스모크: ⚪ 사용자 요청 시에만 진행 (미수행)
- `flutter-code-reviewer`(opus): LGTM

### 머지 / 배포
- `develop` 머지(--no-ff): `71acc3c` (`Merge feature/bloc-03-onboarding: BLoC PR 3 — OnboardingCubit 도입`)
- `origin/develop` push 완료 (`c79fddc..71acc3c` → 문서 커밋 포함 `71acc3c..b81b5d1`)
- `feature/bloc-03-onboarding` 브랜치 보존 (push 완료)

### 다음 세션 즉시 시작 프롬프트 (PR 4 — LibraryCubit)

다음 세션 시작 시 아래 프롬프트를 그대로 복사해 사용:

````
doc/bloc-migration/pr-04-library.md를 정독하고 PR 4(LibraryCubit) 작업을 시작해줘.
이전 세션(PR 3) 결과는 SESSION_LOG.md 최상단에 있어. 아래 컨벤션을 반드시 따를 것.

## PR 1~3에서 확립된 컨벤션

1. **bloc_test 미도입**: cubit 단위 테스트는 `flutter_test` + `Cubit.stream.listen` + `expectLater`
2. **테스트 Hive 격리 path**: `setUpAll`에서 `Hive.init('.dart_tool/test_hive_<name>')` + 필요 box `openBox`, `setUp`에서 `clear`, `tearDownAll`에서 `deleteFromDisk`
3. **전역 vs 화면 로컬 BlocProvider** (README L104): 전역 = ThemeCubit + AuthCubit. **LibraryCubit은 화면 로컬** `BlocProvider`.
4. **StatefulWidget + 화면 로컬 BlocProvider 동시 필요 시**: PR 3에서 확립한 `_XxxBody(StatefulWidget)` 분리 패턴을 기본 선택지로. (provider는 상위 Stateless, 내부 Stateful에서 context.read 접근)
5. **`articlesChangedNotifier`/`labelsChangedNotifier` 브릿지** (README L108 템플릿): PR 4에서 처음 적용. Cubit 생성자에서 `addListener(_onChanged)` → `_onChanged()` = `load()`, `close()`에서 `removeListener`.
6. **CLAUDE.md/플랜 문서의 잔존 언급 무시**: `themeModeNotifier`/`authStateNotifier` — PR 11 cleanup 위임 확정.
7. **브랜치 워크플로**: `develop ↔ origin/develop` 동기화 확인 후 `feature/bloc-04-library` 분기 → `--no-ff` 머지 + push (PR 생성 X, 사용자 승인 후 push)
8. **서브에이전트 모델**: 단순 haiku / 분석 sonnet / 최종 리뷰만 opus `flutter-code-reviewer`
9. **시뮬레이터 스모크**: 사용자가 요청할 때만 진행
10. **기존 `test/widget_test.dart`는 broken**: PR 11 위임

## PR 4 시작 시 즉시 할 일

1. `git status` + `develop`/`origin/develop` 동기화 확인
2. `doc/bloc-migration/pr-04-library.md` 정독 + `lib/screens/library_screen.dart`(445 LOC) Read
3. `git checkout -b feature/bloc-04-library`
4. `flutter analyze` 기준선 확인
5. 작업 계획 한 줄 요약 + 영향 범위 보고 후 시작

## PR 4 알려진 주의사항 (pr-04-library.md 정독 전 참고)

- `LibraryState`는 `Equatable` 기반 상태 클래스 (labels, overall, bookmark, labelStats Map, isLoading). `copyWith` 필수.
- `articlesChangedNotifier` + `labelsChangedNotifier` **두 notifier 동시 구독**. 하나만이라도 변경되면 `load()` 재실행. PR 11까지 브릿지 유지.
- `LibraryScreen`은 로컬 상태 없음 — 기존에도 두 notifier `addListener`로 `setState({})`만 하던 단순 패턴.
- Navigator.push 후 복귀 시에도 `setState({})` 호출하는 라인(L184, L263, L329) → Cubit 전환 후에는 notifier 트리거로 자동 재로드되므로 명시 setState 제거 가능.
- 2열 GridView 구조 (index 0 = 전체, 1 = 북마크, 2+ = 라벨 카드) 유지.
- 데이터 소스 getter: `DatabaseService.getAllLabelObjects / getOverallStats / getBookmarkStats / getLabelStats`.
````

---

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
