# PR 9 — HomeBloc (유일한 Bloc)

> 가장 복잡한 화면. 스와이프 이벤트 다수 + 라벨 필터 + 카드 덱 위치 관리 + CardSwiper 컨트롤러 수명. **Cubit 대신 Bloc을 쓰는 유일한 케이스.**

**의존성**: PR 1, PR 6 (ArticleListCubit 패턴 참고)
**브랜치**: `feature/bloc-09-home`
**예상 작업 시간**: 6~8시간 (최대 PR)
**난이도**: ⭐⭐⭐⭐⭐

---

## 1. 목표

- `lib/blocs/home/home_bloc.dart` + `home_event.dart` + `home_state.dart`
- 이벤트 이벤트 소싱으로 명시화 (스와이프 플로우 디버깅 용이)
- `HomeScreen`의 데이터 상태를 Bloc으로 이동
- **CardSwiper 컨트롤러, pending dispose, cardSwiperKey는 위젯 로컬 유지**
- 유닛 테스트 (이벤트/상태 전이)

---

## 2. 사전 요건 (필독, 가장 긴 화면)

| 파일 | 범위 |
|------|------|
| `lib/screens/home_screen.dart` | 전체 (721 LOC) |
| `lib/widgets/home_overlay_guide.dart` | 기존 유지 (321 LOC) |
| `lib/services/database_service.dart` | `getUnreadArticles`, `getAllLabelObjects`, `markAsRead`, `toggleBookmark`, `updateMemo`, `updateArticleLabels` |
| PR 6의 `ArticleListCubit` | 롱프레스 액션 패턴 참고 |

**핵심 사실**:
- `CardSwiper(isLoop: true)` — 덱 무한 순환
- `_swiperController` 교체가 덱 리셋 시 필요 → `_pendingDispose` 큐로 이중 dispose 방지
- `addPostFrameCallback`에서 컨트롤러 일괄 dispose (try-catch로 방어)
- 8장마다 `SwipeAdCard` 삽입
- 오른쪽 스와이프 = 읽음 처리, 왼쪽 = 나중에
- 라벨 필터 적용 시 덱 리셋

---

## 3. HomeState

`lib/blocs/home/home_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../models/article.dart';
import '../../models/label.dart';

class HomeState extends Equatable {
  final List<Article> articles;        // 현재 필터 적용된 미읽음 덱
  final List<Label> allLabels;
  final Set<String> selectedLabelNames; // 필터. 빈 Set이면 전체
  final bool isExpanded;                // 라벨 칩 그리드 확장 여부
  final int deckVersion;                // 덱 리셋 카운터 (key prop처럼 활용)
  final bool isLoading;

  const HomeState({
    this.articles = const [],
    this.allLabels = const [],
    this.selectedLabelNames = const {},
    this.isExpanded = false,
    this.deckVersion = 0,
    this.isLoading = true,
  });

  HomeState copyWith({
    List<Article>? articles,
    List<Label>? allLabels,
    Set<String>? selectedLabelNames,
    bool? isExpanded,
    int? deckVersion,
    bool? isLoading,
  }) {
    return HomeState(
      articles: articles ?? this.articles,
      allLabels: allLabels ?? this.allLabels,
      selectedLabelNames: selectedLabelNames ?? this.selectedLabelNames,
      isExpanded: isExpanded ?? this.isExpanded,
      deckVersion: deckVersion ?? this.deckVersion,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [articles, allLabels, selectedLabelNames, isExpanded, deckVersion, isLoading];
}
```

**주의**: `deckVersion`은 위젯 쪽에서 `CardSwiper`의 key로 쓸 수 있도록 제공. 필터 변경 / 수동 리셋 시 증가.

---

## 4. HomeEvent

`lib/blocs/home/home_event.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../models/article.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => const [];
}

class HomeLoadDeck extends HomeEvent {
  final bool resetPosition;
  const HomeLoadDeck({this.resetPosition = false});
  @override
  List<Object?> get props => [resetPosition];
}

class HomeFilterLabelsChanged extends HomeEvent {
  final Set<String> names;
  const HomeFilterLabelsChanged(this.names);
  @override
  List<Object?> get props => [names];
}

class HomeSwipeRead extends HomeEvent {
  final Article article;
  const HomeSwipeRead(this.article);
}

class HomeSwipeLater extends HomeEvent {
  final Article article;
  const HomeSwipeLater(this.article);
}

class HomeToggleBookmark extends HomeEvent {
  final Article article;
  const HomeToggleBookmark(this.article);
}

class HomeUpdateMemo extends HomeEvent {
  final Article article;
  final String? memo;
  const HomeUpdateMemo(this.article, this.memo);
}

class HomeEditLabels extends HomeEvent {
  final Article article;
  final List<String> labels;
  const HomeEditLabels(this.article, this.labels);
}

class HomeToggleExpand extends HomeEvent {
  const HomeToggleExpand();
}

class HomeArticlesChangedExternally extends HomeEvent {
  const HomeArticlesChangedExternally();
}
```

---

## 5. HomeBloc

`lib/blocs/home/home_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main.dart' show articlesChangedNotifier, labelsChangedNotifier;
import '../../services/database_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeLoadDeck>(_onLoad);
    on<HomeFilterLabelsChanged>(_onFilter);
    on<HomeSwipeRead>(_onSwipeRead);
    on<HomeSwipeLater>(_onSwipeLater);
    on<HomeToggleBookmark>(_onToggleBookmark);
    on<HomeUpdateMemo>(_onUpdateMemo);
    on<HomeEditLabels>(_onEditLabels);
    on<HomeToggleExpand>((event, emit) {
      emit(state.copyWith(isExpanded: !state.isExpanded));
    });
    on<HomeArticlesChangedExternally>((event, emit) {
      add(const HomeLoadDeck(resetPosition: false));
    });

    articlesChangedNotifier.addListener(_onExtArticles);
    labelsChangedNotifier.addListener(_onExtLabels);
    add(const HomeLoadDeck(resetPosition: true));
  }

  void _onExtArticles() => add(const HomeArticlesChangedExternally());
  void _onExtLabels() => add(const HomeLoadDeck(resetPosition: false));

  Future<void> _onLoad(
    HomeLoadDeck event,
    Emitter<HomeState> emit,
  ) async {
    final labels = DatabaseService.getAllLabelObjects();
    final all = DatabaseService.getUnreadArticles();
    final filtered = state.selectedLabelNames.isEmpty
        ? all
        : all.where((a) => a.topicLabels.any(state.selectedLabelNames.contains)).toList();
    emit(state.copyWith(
      articles: filtered,
      allLabels: labels,
      isLoading: false,
      deckVersion: event.resetPosition ? state.deckVersion + 1 : state.deckVersion,
    ));
  }

  Future<void> _onFilter(
    HomeFilterLabelsChanged event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(selectedLabelNames: event.names));
    add(const HomeLoadDeck(resetPosition: true));
  }

  Future<void> _onSwipeRead(
    HomeSwipeRead event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.markAsRead(event.article);
    // 읽음 처리된 아티클은 덱에서 제거
    final next = state.articles.where((a) => a.key != event.article.key).toList();
    emit(state.copyWith(articles: next));
  }

  Future<void> _onSwipeLater(
    HomeSwipeLater event,
    Emitter<HomeState> emit,
  ) async {
    // "나중에" 는 DB 상태 변경 없음. 덱 루프에서 자연스럽게 다시 등장.
    // 필요 시 최근 N개 회피 로직 (기존 구현 참고)
  }

  Future<void> _onToggleBookmark(
    HomeToggleBookmark event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.toggleBookmark(event.article);
    add(const HomeLoadDeck(resetPosition: false));
  }

  Future<void> _onUpdateMemo(
    HomeUpdateMemo event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.updateMemo(event.article, event.memo);
    add(const HomeLoadDeck(resetPosition: false));
  }

  Future<void> _onEditLabels(
    HomeEditLabels event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.updateArticleLabels(event.article, event.labels);
    add(const HomeLoadDeck(resetPosition: false));
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onExtArticles);
    labelsChangedNotifier.removeListener(_onExtLabels);
    return super.close();
  }
}
```

**주의**:
- `_onSwipeRead`는 **즉시 articles에서 제거**해서 UI 반응성 확보. 그 후 notifier 콜백이 오면 `HomeLoadDeck(resetPosition: false)`으로 한 번 더 갱신되지만 동일 결과.
- `_onSwipeLater`는 상태 변경 불필요. CardSwiper의 loop이 알아서 다음 카드로 넘어감.

---

## 6. HomeScreen 교체

### 6.1 구조

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  CardSwiperController? _swiperController;
  final List<CardSwiperController> _pendingDispose = [];
  int _currentDeckVersion = -1;

  // thresholdNotifier 등 기존 위젯 로컬 상태
  final ValueNotifier<double> _thresholdNotifier = ValueNotifier(0);

  @override
  void dispose() {
    _swiperController?.dispose();
    for (final c in _pendingDispose) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _thresholdNotifier.dispose();
    super.dispose();
  }

  void _syncControllerWithDeckVersion(int newVersion) {
    if (_currentDeckVersion == newVersion) return;
    _currentDeckVersion = newVersion;
    if (_swiperController != null) {
      _pendingDispose.add(_swiperController!);
    }
    _swiperController = CardSwiperController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in _pendingDispose) {
        try {
          c.dispose();
        } catch (_) {}
      }
      _pendingDispose.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (p, c) => p.deckVersion != c.deckVersion,
      listener: (context, state) {
        _syncControllerWithDeckVersion(state.deckVersion);
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.articles.isEmpty) {
          return _EmptyHome(state: state);
        }
        return _DeckContent(
          state: state,
          swiperController: _swiperController!,
          thresholdNotifier: _thresholdNotifier,
          onSwipe: (a, direction) {
            final bloc = context.read<HomeBloc>();
            if (direction == CardSwiperDirection.right) {
              bloc.add(HomeSwipeRead(a));
            } else if (direction == CardSwiperDirection.left) {
              bloc.add(HomeSwipeLater(a));
            }
          },
        );
      },
    );
  }
}
```

### 6.2 _DeckContent

- `CardSwiper`의 `key: ValueKey(state.deckVersion)` → version 바뀌면 위젯 재생성
- `controller: swiperController` (로컬)
- `onSwipe`: Bloc으로 이벤트 dispatch

### 6.3 라벨 필터 칩

```dart
Wrap(
  children: [
    for (final label in state.allLabels)
      FilterChip(
        label: Text(label.name),
        selected: state.selectedLabelNames.contains(label.name),
        onSelected: (_) {
          final next = Set<String>.from(state.selectedLabelNames);
          if (!next.add(label.name)) next.remove(label.name);
          context.read<HomeBloc>().add(HomeFilterLabelsChanged(next));
        },
      ),
    if (state.selectedLabelNames.isNotEmpty)
      ActionChip(
        label: Text(l10n.clear),
        onPressed: () =>
            context.read<HomeBloc>().add(const HomeFilterLabelsChanged({})),
      ),
  ],
)
```

### 6.4 라벨 확장/접기

```dart
IconButton(
  icon: Icon(state.isExpanded ? Icons.expand_less : Icons.expand_more),
  onPressed: () => context.read<HomeBloc>().add(const HomeToggleExpand()),
)
```

### 6.5 롱프레스 액션시트

기존 로직 유지, 액션만 Bloc 이벤트로:

```dart
onTap: () {
  Navigator.pop(context);
  context.read<HomeBloc>().add(HomeToggleBookmark(article));
},
```

### 6.6 광고 카드

`SwipeAdCard`는 articles에 직접 삽입하는 대신 `CardSwiper`의 itemBuilder에서 인덱스 기반으로 분기하는 기존 로직 유지. Bloc 상태에는 순수 아티클 목록만.

---

## 7. 주의사항 (많음!)

### 7.1 컨트롤러 수명과 dispose 타이밍
- **Bloc에 CardSwiperController를 두지 마라**. Widget state에 유지.
- `_pendingDispose` 큐 + `addPostFrameCallback` 패턴 유지. 기존 구현의 방어 코드 참고.

### 7.2 이중 dispose 방지
- `try-catch` 유지. 기존 코드의 경고 주석 참고.

### 7.3 덱 루프와 articles 변경
- `CardSwiper(isLoop: true)` 상태에서 articles가 줄어들면 내부 인덱스가 out-of-range가 될 수 있음.
- 가장 안전한 방법: 덱 변화 시 **ValueKey(deckVersion)로 재생성**. 성능보다 안정성.

### 7.4 스와이프 중 setState 금지
- `_onSwipe` 콜백이 여러 번 호출될 수 있음. Bloc 이벤트는 idempotent하게.

### 7.5 광고 카드 스와이프
- 광고 카드는 read/later 처리 없이 그냥 다음으로 넘어가도록. Bloc 이벤트 발행 안 함.

### 7.6 HomeOverlayGuide
- 별도 위젯. Bloc과 무관. 기존 트리거(첫 실행 감지)는 `MainScreen` 또는 `HomeScreen` 위젯에서 유지.

---

## 8. 테스트

```dart
blocTest<HomeBloc, HomeState>(
  'HomeFilterLabelsChanged updates selectedLabelNames and triggers reload',
  build: () => HomeBloc(),
  skip: 1, // 초기 load
  act: (b) => b.add(const HomeFilterLabelsChanged({'tech'})),
  expect: () => [
    predicate<HomeState>((s) => s.selectedLabelNames.contains('tech')),
  ],
);
```

DatabaseService 의존성이 크므로 통합 테스트는 실기기 QA 의존.

---

## 9. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크 (체크리스트)

- [ ] 앱 시작 → 홈 탭 → 카드 덱 표시
- [ ] 오른쪽 스와이프 → 해당 아티클 읽음 처리, 라이브러리 통계 반영
- [ ] 왼쪽 스와이프 → 상태 변경 없이 다음 카드
- [ ] 덱 끝까지 스와이프 → loop로 다시 처음부터 (단, 읽음 처리된 것은 제외)
- [ ] 라벨 칩 선택 → 덱 즉시 필터링, 첫 카드부터
- [ ] 라벨 칩 여러 개 선택 → 합집합(OR) 필터링
- [ ] 필터 해제 → 전체 덱 복귀
- [ ] 라벨 확장/접기 토글
- [ ] 8번째 카드 위치에 광고 카드 등장, 스와이프 시 상태 영향 없음
- [ ] 롱프레스 → 북마크/메모/라벨 편집 시트
- [ ] 공유 시트로 새 URL 추가 → 덱에 자동 반영 (notifier 브릿지)
- [ ] Firestore 동기화 수신(로그인 상태) → 덱 자동 반영
- [ ] 탭 전환(홈 → 라이브러리 → 홈) → 덱 위치 유지 (setState 없던 기존 동작 보존)
- [ ] 앱 백그라운드 → 포그라운드 → 크래시/상태 꼬임 없음
- [ ] `flutter run --release` 로 빌드 정상 동작 (기존 AdMob/Scene 이슈 재발 체크)

---

## 10. 성능 체크

- 덱 리셋 시 프레임 드랍 모니터 (Flutter DevTools)
- articles.length가 수백 개일 때 CardSwiper 메모리 사용량 확인

---

## 11. 커밋 메시지

```
BLoC PR9: HomeBloc 도입 — 스와이프/필터/덱 관리 이벤트 소싱

- lib/blocs/home/ 신규 (bloc, event, state)
- 스와이프/라벨 필터/확장/외부 변경을 HomeEvent로 명시화
- CardSwiperController 및 pending dispose는 위젯 로컬 유지
- deckVersion으로 덱 리셋 제어 (CardSwiper key prop)
- 광고 카드/오버레이 가이드는 기존 로직 보존
```

---

## 12. 흔한 실수

- `HomeBloc` 내부에서 `CardSwiperController`를 들고 있는 경우 → 절대 안 됨. 위젯 dispose와 Bloc close 타이밍 다름.
- `HomeSwipeRead` 후 상태를 즉시 반영하지 않으면 같은 카드가 덱에 남아있어 revisit됨.
- `deckVersion` 증가 없이 articles만 바꾸면 CardSwiper 내부 인덱스가 out-of-range 에러.
- 필터 선택 시 `HomeLoadDeck(resetPosition: true)` 안 부르면 덱이 뒤죽박죽.

---

## 13. 핸드오프 노트

### 계획대로 된 점
- `lib/blocs/home/{home_bloc,home_event,home_state}.dart` 신규. Bloc 시리즈 유일 Bloc.
- `HomeScreen`을 `StatelessWidget(BlocProvider)` + `_HomeBody(StatefulWidget)`으로 분리. `CardSwiperController` / `_pendingDispose` / `_thresholdNotifier` 위젯 로컬 SSOT.
- `deckVersion` ValueKey 기반 CardSwiper 재생성 — 인덱스 out-of-range 방지.
- `articlesChangedNotifier` / `labelsChangedNotifier` 생성자 addListener, `close()` removeListener. 중복 발사 방지.
- home_bloc_test 14건 신규 + 기존 60 + 신규 14 = 74 전체 PASS.

### 계획과 다르게 된 점
- **필터 로직 AND 채택**: PR 9 문서 스니펫은 `any`(OR)였으나 기존 `HomeScreen._loadArticles`가 `_selectedLabels.every((l) => a.topicLabels.contains(l))` = AND. UX 회귀 방지 위해 **AND 유지**(`_computeFiltered`의 `selected.every` 분기).
- **`HomeEditLabels` 이벤트 드롭**: 기존 `LabelEditSheet`가 이미 `DatabaseService.updateArticleLabels`를 내부 호출. Bloc이 또 호출하면 이중 persist. 시트 await 후 `HomeLoadDeck(resetPosition: false)` 단순 재로드로 대체.
- **`HomeSwipeLater.reachedEnd` 플래그 추가**: 기존 `HomeScreen`은 `currentIndex == null`(loop 경계)일 때 덱 리셋. 플랜 스니펫은 no-op이었으나 기존 동작 보존 위해 `reachedEnd=true`이면 `deckVersion++` emit. DB 상태는 여전히 변경 없음.
- **`HomeSwipeRead`에서 덱 재생성(deckVersion++) 추가**: 플랜은 articles에서만 제거했으나 `isLoop:true` + `numberOfCardsDisplayed=3` 조건에서 인덱스 out-of-range 리스크. 즉시 제거 + deckVersion 증가로 안전성 확보.
- **`refreshToken` 필드 추가(리뷰 should-fix 반영)**: `Article`은 Hive 모델 + `==` 미구현 → in-place `toggleBookmark/updateMemo`가 같은 인스턴스를 공유하는 `articles` 리스트로 재로드되면 Equatable dedup으로 `emit`이 스킵될 위험. 현시점 UI 렌더링 경로에서는 시각적 회귀 없으나 차후 스와이프 카드에 북마크 뱃지/메모 미리보기 추가 시 조용한 갱신 실패 리스크. 매 `_onLoad`마다 `refreshToken++`로 stream emit 강제.
- **`bloc.isClosed` 가드(nit 반영)**: `_showCardActions` → `LabelEditSheet.show` await 후 `bloc.add(...)` 경로에 가드 추가.

### 새로 발견한 이슈 / TODO
- **`_showMemoDialog` 내 `TextEditingController` dispose 미호출**(기존 관례). 시트 pop 시 GC 대상이나 엄밀히는 leak. `dart run build_runner` 수준 아님. PR 11 cleanup에서 시트 공통화 시 정리 권장.
- **하드코딩 숫자/색상**(기존 home_screen.dart 선행). `BorderRadius.circular(20)`, 120/56/36/28/26/16/12 등. PR 9 범위에서 회귀 없음 — PR 11 cleanup 대상.
- **`_SwipeHint` 왼쪽 색상 토큰 불일치**(기존): `onSurfaceVariant` 사용 중. CLAUDE.md의 공용 `swipeSkip=Muted Rose` 토큰과 불일치. PR 9 회귀 아님 — 디자인 의도라면 수용, 아니면 별도 티켓.
- **초기 `_swiperController` 한 인스턴스 낭비**: `_HomeBodyState.initState`에서 `CardSwiperController()` 생성 → 첫 Bloc emit(0→1)에서 곧장 `_pendingDispose`로 이관. 누수 아님, 최적화 여지 낮음.

### 참고한 링크
- `DatabaseService.markAsRead` 시그니처: `lib/services/database_service.dart:116` (notifier 미발사 확인)
- `DatabaseService.updateArticleLabels` 시그니처: `lib/services/database_service.dart:364`
- `LabelEditSheet.show` + 내부 persist: `lib/widgets/label_edit_sheet.dart:19,184`
- `articlesChangedNotifier` 발사원: `ShareService.processAndSave`(`share_service.dart:68`) + `SyncService` 원격 스냅샷(`sync_service.dart:276`)
- CardSwiper key 재생성 패턴: 기존 home_screen.dart:531 `key: ValueKey(_cardSwiperKey)`
- flutter_bloc BlocConsumer: https://bloclibrary.dev/flutter-bloc-concepts/#blocconsumer

### 검증 결과
- `flutter analyze`: ✅ No issues (2.0s)
- `flutter test test/blocs/home_bloc_test.dart`: ✅ 14/14 PASS
- `flutter test test/blocs/`: ✅ 74 PASS (기존 60 + 신규 14)
- opus `flutter-code-reviewer`: must-fix 0, should-fix 1건 반영(refreshToken), nit 1건 반영(bloc.isClosed 가드), nit 3건 범위 외 이관(하드코딩 숫자/토큰 불일치/memo controller dispose)
- 실기기/시뮬레이터 스모크: ⚪ 사용자 방침(전 PR 정리 후 일괄 진행)

### 다음 세션 유의사항
- **PR 10(선택)**: MainScreen ShareFlowCubit. 기본 SKIP. 현 `WidgetsBindingObserver` + `ShareService.checkPendingShares` 경로가 충분히 단순.
- **PR 11**: Cleanup + 문서화. 본 PR의 후속 정리 항목:
  - `labelsChangedNotifier` 로컬 CRUD 미발사 통합(PR 8에서도 이관됨)
  - 시트 공통화 시 `TextEditingController` 라이프사이클 정리
  - 하드코딩 숫자/색상 디자인 토큰 치환
- 현 브랜치: `feature/bloc-09-home`. 머지/푸시는 분리 커밋 + docs 커밋 후 `--no-ff` develop.
