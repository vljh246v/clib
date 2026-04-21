# PR 6 — ArticleListCubit 도입 + AllArticlesScreen

> **이번 리팩터링의 핵심 PR**. AllArticlesScreen/BookmarkedArticlesScreen/LabelDetailScreen 3개가 거의 복붙 구조이므로, 공통 `ArticleListCubit`을 이번 PR에서 설계하고 AllArticlesScreen에 적용한다. 나머지 두 화면은 PR 7에서 재사용.

**의존성**: PR 1
**브랜치**: `feature/bloc-06-article-list`
**예상 작업 시간**: 4~6시간 (최대 PR)
**난이도**: ⭐⭐⭐⭐

---

## 1. 목표

- `lib/blocs/article_list/article_list_cubit.dart` + `article_list_state.dart` 신규
- **Source 개념**: `ArticleListSource.all() / bookmarked() / byLabel(String name)`
- 상태: articles, tabIndex, isSelecting, selectedKeys, isLoading
- 메서드:
  - `load()`, `changeTab(int)`
  - `toggleSelectMode()`, `selectAll()`, `toggleItem(dynamic key)`, `clearSelection()`
  - `bulkMarkRead(bool)`, `bulkDelete()`, `bulkToggleBookmark(bool)`
  - `toggleBookmark(Article)`, `updateMemo(Article, String?)`, `markRead(Article)`, `markUnread(Article)`, `deleteArticle(Article)`
- AllArticlesScreen을 BlocProvider로 감싸고 source=all 주입, `setState` 전부 제거
- **광고 삽입 로직을 공통 위젯 `lib/widgets/article_list_view.dart`로 추출**
- 유닛 테스트 (상태 변이 중심)

---

## 2. 사전 요건 (필독)

| 파일 | 범위 |
|------|------|
| `lib/screens/all_articles_screen.dart` | 전체 (728 LOC) |
| `lib/services/database_service.dart` | getAllArticles, getBookmarkedArticles, getArticlesByLabel, bulkMarkRead, bulkSetBookmark, deleteArticle, toggleBookmark, updateMemo, markAsRead/Unread |
| `lib/widgets/inline_banner_ad.dart` | 그대로 사용 |
| `lib/models/article.dart` | Article 필드 확인 |

**핵심 사실**:
- 3개 탭 구조: 전체 / 안 읽음 / 읽음 (TabController length=3)
- 각 탭은 동일 source(예: "전체")의 필터링된 뷰
- 다중선택 모드에서 선택 키는 Hive key (`article.key`) — `dynamic` 타입 (일반적으로 int)
- 광고는 8개 아티클마다 `InlineBannerAd` 삽입

---

## 3. Source enum

> ⚠️ **실제 구현과 다름** — 계획의 private 서브클래스 + factory constructor 패턴은 컴파일 실패.
> **실제 구현**은 아래 "13. 핸드오프 노트 > 계획과 다르게 된 점 #1" 참조.

`lib/blocs/article_list/article_list_source.dart` (실제 구현):

```dart
import 'package:equatable/equatable.dart';

sealed class ArticleListSource extends Equatable {
  const ArticleListSource();
}

final class ArticleListSourceAll extends ArticleListSource {
  const ArticleListSourceAll();
  @override List<Object?> get props => [];
}

final class ArticleListSourceBookmarked extends ArticleListSource {
  const ArticleListSourceBookmarked();
  @override List<Object?> get props => [];
}

final class ArticleListSourceByLabel extends ArticleListSource {
  const ArticleListSourceByLabel(this.labelName);
  final String labelName;
  @override List<Object?> get props => [labelName];
}
```

**이유**: sealed class의 private 서브클래스는 다른 파일에서 패턴 매칭 불가.
사용 시: `ArticleListSourceAll()`, `ArticleListSourceBookmarked()`, `ArticleListSourceByLabel('라벨명')`.

---

## 4. State

> ⚠️ **실제 구현과 다름** — `tabIndex`, `isLoading`, `visibleArticles` getter, `Set<dynamic>` 모두 미채택.
> **실제 구현**은 아래 "13. 핸드오프 노트 > 계획과 다르게 된 점 #2~3" 참조.

`lib/blocs/article_list/article_list_state.dart` (실제 구현):

```dart
class ArticleListState extends Equatable {
  const ArticleListState({
    required this.source,
    this.articles = const [],
    this.isSelecting = false,
    this.selectedKeys = const [],
    this.generation = 0,
  });

  final ArticleListSource source;
  final List<Article> articles;
  final bool isSelecting;
  final List<dynamic> selectedKeys;  // Set 아님 — Equatable 안전성
  final int generation;              // load()마다 +1, Hive in-place 변경 Equatable 우회

  // 파생 getters
  int get total => articles.length;
  int get readCount => articles.where((a) => a.isRead).length;
  int get unreadCount => articles.where((a) => !a.isRead).length;
  List<Article> get readArticles => articles.where((a) => a.isRead).toList();
  List<Article> get unreadArticles => articles.where((a) => !a.isRead).toList();
  bool allSelectedFor(List<Article> visible) =>
      visible.isNotEmpty && visible.every((a) => selectedKeys.contains(a.key));

  @override
  List<Object?> get props => [source, articles, isSelecting, selectedKeys, generation];
}
```

**핵심 설계 결정**:
- `tabIndex`는 State에 없음. TabController는 StatefulWidget에서만 vsync 가능 → 탭 필터링은 위젯이 담당.
- `generation`은 Hive in-place 변경 시 Equatable이 emit을 스킵하는 문제를 해결.
- `selectedKeys`는 List (Set 아님) — Equatable의 컬렉션 동등성 처리 일관성 보장.

---

## 5. Cubit

> ⚠️ **계획과 다른 점** — `changeTab()` 없음, `toggleItem()` → `toggleSelection()`, `selectAll()` 파라미터 추가, 이중 emit 패턴 → `_reloadAndClearSelection()` 단일 emit.

`lib/blocs/article_list/article_list_cubit.dart` (실제 구현):

```dart
class ArticleListCubit extends Cubit<ArticleListState> {
  ArticleListCubit(ArticleListSource source)
      : super(ArticleListState(source: source)) {
    articlesChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => unawaited(load());

  Future<void> load() async {
    emit(state.copyWith(articles: _fetch(), generation: state.generation + 1));
  }

  List<Article> _fetch() => switch (state.source) {
    ArticleListSourceAll() => DatabaseService.getAllArticles(),
    ArticleListSourceBookmarked() => DatabaseService.getBookmarkedArticles(),
    ArticleListSourceByLabel(:final labelName) =>
        DatabaseService.getArticlesByLabel(labelName),
  };

  // 선택 모드
  void toggleSelectMode() =>
      emit(state.copyWith(isSelecting: !state.isSelecting, selectedKeys: []));
  void clearSelection() =>
      emit(state.copyWith(isSelecting: false, selectedKeys: []));
  void toggleSelection(dynamic key) {
    final next = List<dynamic>.from(state.selectedKeys);
    next.contains(key) ? next.remove(key) : next.add(key);
    emit(state.copyWith(selectedKeys: next));
  }
  void selectAll(List<Article> visibleArticles) {
    // 현재 탭의 가시 목록을 파라미터로 받음 (tabIndex 없으므로)
    final keys = visibleArticles.map((a) => a.key).toList();
    emit(state.copyWith(selectedKeys: keys));
  }

  // 일괄 작업 — _reloadAndClearSelection() 단일 emit (이중 emit 방지)
  Future<void> bulkMarkRead(bool read) async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key)).toList();
    await DatabaseService.bulkMarkRead(targets, read);
    await _reloadAndClearSelection();
  }
  Future<void> bulkToggleBookmark(bool bookmark) async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key)).toList();
    await DatabaseService.bulkSetBookmark(targets, bookmark);
    await _reloadAndClearSelection();
  }
  Future<void> bulkDelete() async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key)).toList();
    for (final a in targets) await DatabaseService.deleteArticle(a);
    await _reloadAndClearSelection();
  }

  Future<void> _reloadAndClearSelection() async {
    emit(state.copyWith(
      articles: _fetch(), isSelecting: false, selectedKeys: [],
      generation: state.generation + 1,
    ));
  }

  // 개별 작업
  Future<void> toggleBookmark(Article a) async {
    await DatabaseService.toggleBookmark(a); await load();
  }
  Future<void> updateMemo(Article a, String? memo) async {
    await DatabaseService.updateMemo(a, memo); await load();
  }
  Future<void> markRead(Article a) async {
    await DatabaseService.markAsRead(a); await load();
  }
  Future<void> markUnread(Article a) async {
    await DatabaseService.markAsUnread(a); await load();
  }
  Future<void> deleteArticle(Article a) async {
    await DatabaseService.deleteArticle(a); await load();
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
```

**핵심 결정**:
- `changeTab()` 없음 — tabIndex를 State에서 제거했으므로.
- `selectAll(visibleArticles)` — 현재 탭 목록을 호출 측에서 전달.
- 이중 emit(`clearSelection()` + `load()`)은 broadcast stream async 특성상 테스트 타이밍 이슈 유발. `_reloadAndClearSelection()` 단일 emit으로 통합.
- `articlesChangedNotifier`는 `ShareService.processAndSave()`만 트리거. Cubit 내부 write 후에는 반드시 직접 `load()` 필요.

---

## 6. 공통 위젯 추출: `ArticleListView` + `ArticleListItem`

> ⚠️ **실제 구현과 다름** — `ArticleCard`는 HomeScreen 스와이프 카드 전용. 리스트 행은 새 위젯 필요.
> `selectedKeys`는 `Set`이 아닌 `List<dynamic>`. `onToggleSelect` 서명도 다름.

`lib/widgets/article_list_view.dart` (실제 서명):

```dart
class ArticleListView extends StatelessWidget {
  const ArticleListView({
    super.key,
    required this.articles,
    required this.isSelecting,
    required this.selectedKeys,       // List<dynamic>, Set 아님
    required this.onTap,              // void Function(Article)
    required this.onSelectionToggle,  // void Function(dynamic key)
    required this.emptyWidget,        // Widget, builder 아님
    this.onLongPress,                 // void Function(Article)?
  });
}
```

광고 삽입 공식: `adCount > 0 && index > 0 && (index + 1) % (adInterval + 1) == 0` (adInterval=8)

`lib/widgets/article_list_item.dart` (신규, 실제 리스트 행):
- `ArticleCard`를 재사용하지 않음. 새 `ArticleListItem` StatelessWidget.
- 파라미터: `article, isSelecting, isSelected, onTap, onSelectionToggle, onLongPress?`

`lib/widgets/bulk_action_bar.dart` (신규, 공용 위젯):
- 계획의 `_BulkActionBar` private → public `BulkActionBar` 위젯으로 추출 (PR 7에서 재사용)
- 2행 5버튼: [북마크 추가 | 북마크 해제] / [안읽음 | 읽음 | 삭제(error색)]
- 파라미터: `onBookmark, onRemoveBookmark, onMarkUnread, onMarkRead, onDelete` (모두 VoidCallback)

---

## 7. AllArticlesScreen 교체

### 7.1 BlocProvider + BlocBuilder

```dart
class AllArticlesScreen extends StatelessWidget {
  const AllArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(const ArticleListSource.all()),
      child: const _AllArticlesBody(),
    );
  }
}
```

### 7.2 _AllArticlesBody

```dart
class _AllArticlesBody extends StatefulWidget {
  const _AllArticlesBody();
  @override
  State<_AllArticlesBody> createState() => _AllArticlesBodyState();
}

class _AllArticlesBodyState extends State<_AllArticlesBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      context.read<ArticleListCubit>().changeTab(_tab.index);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ArticleListCubit, ArticleListState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: state.isSelecting
                ? Text(l10n.selectedCount(state.selectedKeys.length))
                : Text(l10n.allArticles),
            actions: [
              if (state.isSelecting)
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () =>
                      context.read<ArticleListCubit>().selectAll(),
                ),
              IconButton(
                icon: Icon(state.isSelecting ? Icons.close : Icons.check_circle_outline),
                onPressed: () =>
                    context.read<ArticleListCubit>().toggleSelectMode(),
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: [
                Tab(text: l10n.tabAll),
                Tab(text: l10n.tabUnread),
                Tab(text: l10n.tabRead),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: List.generate(3, (_) => _buildList(context, state)),
          ),
          bottomNavigationBar: state.isSelecting
              ? _BulkActionBar(state: state)
              : null,
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ArticleListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ArticleListView(
      articles: state.visibleArticles,
      isSelecting: state.isSelecting,
      selectedKeys: state.selectedKeys,
      onTap: (a) => _openArticle(a),
      onLongPress: (a) => _showActionSheet(context, a),
      onToggleSelect: (a) =>
          context.read<ArticleListCubit>().toggleItem(a.key),
    );
  }
}
```

### 7.3 `_BulkActionBar`

```dart
class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({required this.state});
  final ArticleListState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ArticleListCubit>();
    final l10n = AppLocalizations.of(context)!;
    return BottomAppBar(
      child: Row(
        children: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l10n.bulkMarkRead),
            onPressed: () => cubit.bulkMarkRead(true),
          ),
          TextButton.icon(
            icon: const Icon(Icons.bookmark_outline),
            label: Text(l10n.bulkBookmark),
            onPressed: () => cubit.bulkToggleBookmark(true),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.bulkDelete),
            onPressed: () async {
              final ok = await _confirmDelete(context, state.selectedKeys.length);
              if (ok) await cubit.bulkDelete();
            },
          ),
        ],
      ),
    );
  }
}
```

### 7.4 롱프레스 액션시트

기존 `_showActionSheet` 함수를 유지하고, 내부 액션만 `context.read<ArticleListCubit>()`로 교체.

---

## 8. 주의사항

- **TabController는 위젯 state에 유지**. Cubit으로 옮기면 vsync 제공 불가.
- `state.visibleArticles`는 getter로 계산. 리빌드마다 실행되지만 리스트 크기가 작아 성능 영향 미미.
- `_tab.indexIsChanging` 체크를 빼먹으면 스와이프 중간에 changeTab이 두 번 불릴 수 있음.
- `bulkDelete`는 트랜잭션 없이 순차 삭제. 중간 실패 시 일부만 삭제됨. 별도 개선 티켓으로 기록.
- 광고 위젯은 플랫폼별 초기화 상태에 따라 `SizedBox.shrink()`로 fallback 될 수 있으니 기존 `InlineBannerAd` 동작 확인.

---

## 9. 테스트

`test/blocs/article_list_cubit_test.dart`:

```dart
group('ArticleListState', () {
  test('visibleArticles filters by tabIndex', () {
    final a1 = Article(url: '1', title: 'u', isRead: false, /* ... */);
    final a2 = Article(url: '2', title: 'r', isRead: true, /* ... */);
    final state = ArticleListState(articles: [a1, a2]);

    expect(state.copyWith(tabIndex: 0).visibleArticles.length, 2);
    expect(state.copyWith(tabIndex: 1).visibleArticles, [a1]);
    expect(state.copyWith(tabIndex: 2).visibleArticles, [a2]);
  });
});
```

Cubit 통합 테스트는 DatabaseService 설정이 복잡하면 스킵하고 실기기 QA로 커버 (핸드오프 노트 기록).

---

## 10. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크 (3탭 공통 시나리오)

- [ ] 전체/안읽음/읽음 탭 전환 시 목록 필터링 정상
- [ ] 다중선택 진입 → 셀 탭으로 체크 → "전체 선택" 확인
- [ ] 일괄 읽음 / 일괄 북마크 / 일괄 삭제 정상 동작
- [ ] 일괄 동작 후 선택 모드 해제 + 선택 초기화
- [ ] 롱프레스 액션시트: 북마크 토글, 메모 수정, 읽음/안읽음 토글, 삭제
- [ ] 아티클 탭 → 브라우저 열림
- [ ] 광고: 8개마다 배너 등장, 마지막 아이템 뒤에는 없음
- [ ] 공유 시트로 새 아티클 추가 → notifier 브릿지로 자동 갱신
- [ ] Firestore 동기화: 로그인 상태에서 일괄 읽음 → 서버 반영 즉시 확인

---

## 11. 커밋 메시지

```
BLoC PR6: ArticleListCubit 도입 + AllArticlesScreen 전환

- lib/blocs/article_list/ 신규: sealed Source + Cubit + State
- lib/widgets/article_list_view.dart 추출 (광고 삽입 공통화)
- AllArticlesScreen StatelessWidget + BlocBuilder 전환
- 다중선택/일괄 액션/롱프레스 시트 Cubit 경유로 교체
- visibleArticles getter로 탭 필터링 캡슐화
```

---

## 12. PR 7과의 연계

이번 PR에서 Cubit과 ArticleListView가 **재사용 가능**하게 잘 설계되어야 PR 7이 단순해진다. 끝내기 전 다음 체크:

- [ ] ArticleListCubit이 `source` 외 모든 것을 공통화했는가?
- [ ] ArticleListView가 AppBar 외 모든 공통 UI를 포함하는가?
- [ ] `_BulkActionBar`도 재사용 가능한가?

안 되어 있으면 이번 PR에서 마저 작업.

---

## 13. 핸드오프 노트

> **세션 완료일**: 2026-04-21

### 계획대로 된 점

- `ArticleListCubit` + `ArticleListState` + `ArticleListSource` 3파일 분리 구조
- `articlesChangedNotifier` 브릿지: 생성자 `addListener`, `close()` `removeListener`
- `AllArticlesScreen` → StatelessWidget + `BlocProvider` 전환
- `ArticleListView` 공통 위젯 추출 (광고 삽입 포함)
- 롱프레스 액션시트 / 메모 바텀시트 Cubit 경유로 교체
- 다중선택 + 일괄 읽음/북마크/삭제 (BulkActionBar)
- 유닛 테스트 22개 작성 및 통과

### 계획과 다르게 된 점

1. **Source 클래스: private 서브클래스 → public `final class`**
   - 계획: `ArticleListSource.all()` 등 factory constructor + private `_All`, `_Bookmarked`, `_ByLabel`
   - 실제: `ArticleListSourceAll`, `ArticleListSourceBookmarked`, `ArticleListSourceByLabel` (public, 접두사 방식)
   - 이유: sealed class의 private 서브클래스는 다른 파일에서 exhaustive pattern matching 불가 → 컴파일 실패

2. **State: `tabIndex` / `isLoading` 제거, `generation` 추가, `Set` → `List`**
   - `tabIndex` 제거: TabController는 vsync 필요 → StatefulWidget에 유지. 탭 필터링은 `_tabController.index` switch로 위젯에서 처리.
   - `isLoading` 제거: 초기 로드가 동기에 가까워 불필요.
   - `generation: int` 추가: Hive 객체 in-place 변경 후 `_DeepCollectionEquality`가 동일 참조를 equal 판단 → `emit()` 스킵 문제 해결. `load()` 호출마다 `generation + 1`.
   - `selectedKeys: List<dynamic>` (Set 아님): Equatable 컬렉션 동등성 일관성 보장.

3. **`visibleArticles` getter: State → 위젯**
   - 탭 필터링(`state.unreadArticles`, `state.readArticles` getter)은 State에 있으나, 어느 getter를 쓸지는 위젯의 `_tabController.index`가 결정.

4. **Cubit 메서드명 변경**
   - `changeTab(int)` → 없음
   - `toggleItem(dynamic key)` → `toggleSelection(dynamic key)`
   - `selectAll()` → `selectAll(List<Article> visibleArticles)` (현재 탭 가시 목록을 파라미터로)

5. **이중 emit 패턴 → `_reloadAndClearSelection()` 단일 emit**
   - 계획: bulk 작업 후 `clearSelection()` + `load()` 순차 호출 (2번 emit)
   - 실제: `_reloadAndClearSelection()` 단일 헬퍼로 통합 (1번 emit)
   - 이유: `flutter_bloc` broadcast stream은 async. 2번 emit 시 테스트에서 중간 상태(`isSelecting: false, articles: old`)를 관찰해 `Expected: 1, Actual: 2` 류 실패 발생.

6. **`ArticleCard` 재사용 불가 → `ArticleListItem` 신규**
   - `ArticleCard`는 HomeScreen의 스와이프 덱 전용 (카드형 레이아웃). 리스트 행에는 맞지 않음.
   - `ArticleListItem` (lib/widgets/) 새로 작성.

7. **`BulkActionBar`: 화면 private → 공용 public 위젯**
   - 계획: `_BulkActionBar` 화면 내 private 위젯
   - 실제: `lib/widgets/bulk_action_bar.dart` 공용 위젯 (PR 7에서 3화면 재사용 위해)
   - 버튼 구성 차이: 계획(3버튼) vs 실제(5버튼: 북마크 추가/해제, 안읽음, 읽음, 삭제)

8. **`_MemoSheet`: 인라인 builder → StatefulWidget 분리**
   - `TextEditingController` 라이프사이클 보장을 위해 `_MemoSheet` private StatefulWidget으로 분리.
   - `dispose()`에서 controller 해제.

9. **Tab listener: `changeTab()` → `clearSelection()` + `setState()`**
   - `changeTab()` 제거됨에 따라, 탭 전환 시 `cubit.clearSelection()` + `setState(() {})`.
   - `setState()`가 없으면 Equatable이 selectedKeys 변화 없을 때 BlocBuilder를 rebuild 스킵 → 탭 헤더가 stale.

### 새로 발견한 이슈 / TODO

1. **Hive in-place 변경 + Equatable 문제** → `generation` 카운터로 해결
2. **`articlesChangedNotifier`는 `ShareService`만 트리거** — Cubit 내부 write 후 반드시 `load()` 직접 호출 필요
3. **`labelsChangedNotifier` 구독 불필요** — 아티클 목록은 라벨 메타 변경에 영향받지 않음
4. **`ArticleListSourceByLabel(labelName)` stale 문제** — 라벨 이름 변경 시 현재 화면의 source가 구버전 이름을 유지 → 다음 `load()`가 빈 리스트 반환. PR 7에서 LabelDetailScreen 구현 시 주의 (편집 후 화면 pop 유도).
5. **`firebase_core` 미초기화 테스트 이슈** → `DatabaseService.skipSync = true` 설정으로 해결
6. **broadcast stream async → 테스트 타이밍** → `await Future<void>.delayed(Duration.zero)` 필요

### 참고한 링크

- flutter_bloc broadcast stream 동작: https://bloclibrary.dev/bloc-concepts/#streams
- Equatable DeepCollectionEquality: https://pub.dev/packages/equatable

### 다음 세션 유의사항 (PR 7)

**반드시 확인할 실제 API** (계획 문서의 예제 코드 믿지 말 것):

- Source 클래스: `ArticleListSourceAll()`, `ArticleListSourceBookmarked()`, `ArticleListSourceByLabel(labelName)` — factory constructor 없음
- `ArticleListView` 실제 서명:
  ```dart
  ArticleListView(
    articles: ...,
    isSelecting: state.isSelecting,
    selectedKeys: state.selectedKeys,       // List<dynamic>
    onTap: (article) { ... },
    onSelectionToggle: (key) => cubit.toggleSelection(key),
    emptyWidget: ...,                        // Widget, not builder
    onLongPress: (article) { ... },
  )
  ```
- `BulkActionBar` 재사용 가능 (lib/widgets/bulk_action_bar.dart)
- `_MemoSheet` 패턴 재사용 (LabelDetailScreen도 메모 다이얼로그 있음)
- Tab listener: `clearSelection()` + `setState(() {})` (changeTab 없음)
- `selectAll(visibleArticles)` — 현재 탭의 가시 아티클 목록 전달
- **LabelDetailScreen 고유 요소**: `labelColor = Color(label.colorValue)`, 통계 헤더, 라벨 첫 글자 아이콘. `state.articles`로 파생 계산.
- **ArticleListScreenBody 공통 위젯 불필요** — 각 화면 AppBar 로직이 충분히 다름. 오버엔지니어링.
- 테스트: `DatabaseService.skipSync = true` + bulk 작업 후 `await Future<void>.delayed(Duration.zero)`

### 검증 결과

- `flutter analyze`: No issues ✓
- `flutter test`: 22개 테스트 전부 통과 ✓
- 실기기 스모크: 미수행 (실기기 접근 불가) — PR 7 시작 전 또는 PR 리뷰 시 수행 권장
