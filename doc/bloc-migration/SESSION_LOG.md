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
