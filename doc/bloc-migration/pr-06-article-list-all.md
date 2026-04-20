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

`lib/blocs/article_list/article_list_source.dart`:

```dart
import 'package:equatable/equatable.dart';

sealed class ArticleListSource extends Equatable {
  const ArticleListSource();

  const factory ArticleListSource.all() = _All;
  const factory ArticleListSource.bookmarked() = _Bookmarked;
  const factory ArticleListSource.byLabel(String name) = _ByLabel;
}

class _All extends ArticleListSource {
  const _All();
  @override
  List<Object?> get props => const ['all'];
}

class _Bookmarked extends ArticleListSource {
  const _Bookmarked();
  @override
  List<Object?> get props => const ['bookmarked'];
}

class _ByLabel extends ArticleListSource {
  final String name;
  const _ByLabel(this.name);
  @override
  List<Object?> get props => ['byLabel', name];
}
```

**주의**: Dart 3의 sealed class 사용. 코드에서는 pattern matching 또는 `is` 체크.

---

## 4. State

`lib/blocs/article_list/article_list_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../models/article.dart';

class ArticleListState extends Equatable {
  final List<Article> articles;     // source 기준 전체 목록
  final int tabIndex;               // 0=전체, 1=안읽음, 2=읽음
  final bool isSelecting;
  final Set<dynamic> selectedKeys;  // Hive keys
  final bool isLoading;

  const ArticleListState({
    this.articles = const [],
    this.tabIndex = 0,
    this.isSelecting = false,
    this.selectedKeys = const {},
    this.isLoading = true,
  });

  /// 현재 탭 기준 필터링된 목록.
  List<Article> get visibleArticles {
    switch (tabIndex) {
      case 1:
        return articles.where((a) => !a.isRead).toList();
      case 2:
        return articles.where((a) => a.isRead).toList();
      default:
        return articles;
    }
  }

  ArticleListState copyWith({
    List<Article>? articles,
    int? tabIndex,
    bool? isSelecting,
    Set<dynamic>? selectedKeys,
    bool? isLoading,
  }) {
    return ArticleListState(
      articles: articles ?? this.articles,
      tabIndex: tabIndex ?? this.tabIndex,
      isSelecting: isSelecting ?? this.isSelecting,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [articles, tabIndex, isSelecting, selectedKeys, isLoading];
}
```

---

## 5. Cubit

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main.dart' show articlesChangedNotifier;
import '../../models/article.dart';
import '../../services/database_service.dart';
import 'article_list_source.dart';
import 'article_list_state.dart';

class ArticleListCubit extends Cubit<ArticleListState> {
  ArticleListCubit(this.source) : super(const ArticleListState()) {
    articlesChangedNotifier.addListener(_onChanged);
    load();
  }

  final ArticleListSource source;

  void _onChanged() => load();

  Future<void> load() async {
    final list = _fetch();
    emit(state.copyWith(articles: list, isLoading: false));
  }

  List<Article> _fetch() {
    return switch (source) {
      _All() => DatabaseService.getAllArticles(),
      _Bookmarked() => DatabaseService.getBookmarkedArticles(),
      _ByLabel(name: final n) => DatabaseService.getArticlesByLabel(n),
    };
  }

  void changeTab(int index) {
    if (state.tabIndex == index) return;
    emit(state.copyWith(
      tabIndex: index,
      selectedKeys: const {},
    ));
  }

  void toggleSelectMode() {
    emit(state.copyWith(
      isSelecting: !state.isSelecting,
      selectedKeys: const {},
    ));
  }

  void toggleItem(dynamic key) {
    final next = Set<dynamic>.from(state.selectedKeys);
    if (!next.add(key)) next.remove(key);
    emit(state.copyWith(selectedKeys: next));
  }

  void selectAll() {
    final keys = state.visibleArticles.map((a) => a.key).toSet();
    emit(state.copyWith(selectedKeys: keys));
  }

  void clearSelection() {
    emit(state.copyWith(selectedKeys: const {}, isSelecting: false));
  }

  Future<void> bulkMarkRead(bool read) async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key))
        .toList();
    await DatabaseService.bulkMarkRead(targets, read);
    clearSelection();
    await load();
  }

  Future<void> bulkToggleBookmark(bool bookmark) async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key))
        .toList();
    await DatabaseService.bulkSetBookmark(targets, bookmark);
    clearSelection();
    await load();
  }

  Future<void> bulkDelete() async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key))
        .toList();
    for (final a in targets) {
      await DatabaseService.deleteArticle(a);
    }
    clearSelection();
    await load();
  }

  Future<void> toggleBookmark(Article a) async {
    await DatabaseService.toggleBookmark(a);
    await load();
  }

  Future<void> updateMemo(Article a, String? memo) async {
    await DatabaseService.updateMemo(a, memo);
    await load();
  }

  Future<void> markRead(Article a) async {
    await DatabaseService.markAsRead(a);
    await load();
  }

  Future<void> markUnread(Article a) async {
    await DatabaseService.markAsUnread(a);
    await load();
  }

  Future<void> deleteArticle(Article a) async {
    await DatabaseService.deleteArticle(a);
    await load();
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
```

**주의**:
- `DatabaseService.bulkMarkRead` / `bulkSetBookmark` 호출이 이미 Firestore batch write를 포함하므로 중복 동기화 없음.
- `bulkDelete`는 루프 처리. 최적화가 필요하면 `DatabaseService`에 `bulkDelete` 추가를 별도 PR로 검토.
- `a.key`는 Hive key로 int (또는 String). `dynamic`으로 호환.

---

## 6. 공통 위젯 추출: `ArticleListView`

`lib/widgets/article_list_view.dart` 신규:

```dart
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../widgets/article_card.dart';
import '../widgets/inline_banner_ad.dart';

class ArticleListView extends StatelessWidget {
  const ArticleListView({
    super.key,
    required this.articles,
    required this.onTap,
    required this.onLongPress,
    this.isSelecting = false,
    this.selectedKeys = const {},
    this.onToggleSelect,
    this.adInterval = 8,
    this.emptyBuilder,
  });

  final List<Article> articles;
  final void Function(Article) onTap;
  final void Function(Article) onLongPress;
  final bool isSelecting;
  final Set<dynamic> selectedKeys;
  final void Function(Article)? onToggleSelect;
  final int adInterval;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    // 광고 삽입 고려하여 전체 아이템 수 계산
    final items = <Widget>[];
    for (var i = 0; i < articles.length; i++) {
      final a = articles[i];
      items.add(_ArticleRow(
        article: a,
        isSelecting: isSelecting,
        isSelected: selectedKeys.contains(a.key),
        onTap: () {
          if (isSelecting) {
            onToggleSelect?.call(a);
          } else {
            onTap(a);
          }
        },
        onLongPress: () => onLongPress(a),
      ));
      // 8개마다 배너(마지막은 제외)
      if ((i + 1) % adInterval == 0 && i != articles.length - 1) {
        items.add(const InlineBannerAd());
      }
    }

    return ListView(children: items);
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({
    required this.article,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Article article;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    // ArticleCard 기존 props에 맞춰 작성
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          if (isSelecting)
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
            ),
          Expanded(child: ArticleCard(article: article)),
        ],
      ),
    );
  }
}
```

**주의**: 기존 `ArticleCard`의 실제 생성자와 props를 확인하고 맞춘다. 롱프레스/탭 로직은 각 화면의 기존 구현을 그대로 이식.

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

### 계획대로 된 점
- (작성)

### 계획과 다르게 된 점
- (작성)

### 새로 발견한 이슈 / TODO
- (작성)

### 참고한 링크
- (작성)

### 다음 세션 유의사항 (특히 PR 7)
- (작성)

### 검증 결과
- (작성)
